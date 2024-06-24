# use libgirepository to produce Julia declarations and methods

const_expr(name,val) =  :(const $(Symbol(name)) = $(val))
enum_fullname(enumname,name) = Symbol(enumname,"_",symuppercase(name))
enum_name(enum) = Symbol(string(get_namespace(enum),get_name(enum)))

function find_symbol(l,id)
    lo = dlopen(l)
    isnothing(lo) && return false
    sym=dlsym(lo,id;throw_error=false)
    return sym!==nothing
end

find_symbol(id) = Base.Fix2(find_symbol, id)

function typeinit_def(info, gstructname = get_name(info))
    type_init = String(get_type_init(info))
    libs=get_shlibs(GINamespace(get_namespace(info)))
    lib=libs[findfirst(find_symbol(type_init),libs)]
    quote
        GLib.g_type(::Type{T}) where {T <: $gstructname} =
            ccall(($type_init, $(symbol_from_lib(lib))), GType, ())
    end
end

function append_type_init(body, enum, incl_typeinit)
    bloc = Expr(:block, unblock(body))
    # if this enum has a GType we define GLib.g_type() to support storing this in GValue
    if incl_typeinit && get_type_init(enum) !== :nothing
        push!(bloc.args,unblock(typeinit_def(enum)))
    end
    unblock(bloc)
end

# export as a Cenum type
function decl(enum::GIEnumInfo, incl_typeinit=true)
    enumname=get_name(enum)
    vals = get_enum_values(enum)
    typ = typetag_primitive[get_storage_type(enum)]
    body = Expr(:macrocall, Symbol("@cenum"), Symbol("nothing"), :($enumname::$typ))
    for (name,val) in vals
        val=unsafe_trunc(typ,val)  # sometimes the value returned by GI is outside the range of the enum's type
        fullname=enum_fullname(enumname,name)
        push!(body.args, :($fullname = $val) )
    end
    append_type_init(body, enum, incl_typeinit)
end

# use BitFlags.jl
function decl(enum::GIFlagsInfo, incl_typeinit=true)
    enumname=get_name(enum)
    vals = get_enum_values(enum)
    typ = typetag_primitive[get_storage_type(enum)]
    body = Expr(:macrocall, Symbol("@bitflag"), Symbol("nothing"), :($enumname::UInt32))
    seen=UInt32[]
    for (name,val) in vals
        val=unsafe_trunc(typ,val)  # sometimes the value returned by GI is outside the range of the enum's type
        if (iszero(val) || ispow2(val)) && !in(val,seen)
            fullname=enum_fullname(enumname,name)
            push!(body.args, :($fullname = $val) )
            push!(seen,val)
        end
    end
    if !in(zero(UInt32),seen)
        fullname=enum_fullname(enumname,"NONE")
        push!(body.args, :($fullname = 0))
    end
    append_type_init(body, enum, incl_typeinit)
end

## Struct output

# Opaque structs (where the contents are not part of the public API) are
# exported with a "handle" field.

# Non-opaque structs can be outputted too but details are still being worked out

# get the thing that should go inside the curly brackets in Ptr{}
function get_struct_name(structinfo,force_opaque=false)
    opaque = force_opaque || isopaque(structinfo)
    gstructname = get_full_name(structinfo)
    opaque ? gstructname : Symbol("_",gstructname)
end

function decl(structinfo::GIStructInfo,force_opaque=false)
    gstructname = get_full_name(structinfo)
    gtype=get_g_type(structinfo)
    isboxed = GLib.g_isa(gtype,GLib.g_type(GBoxed))
    ustructname=get_struct_name(structinfo,force_opaque)
    opaque = force_opaque || isopaque(structinfo)
    ctypename = opaque ? :GBoxed : :(Union{GBoxed,$ustructname})
    exprs=Expr[]
    if isboxed
        fin = quote
            $(unblock(typeinit_def(structinfo,gstructname)))
            function $gstructname(ref::Ptr{T}, own::Bool = false) where {T <: $ctypename}
                #println("constructing ",$(QuoteNode(gstructname)), " ",own)
                x = new(ref)
                if own
                    finalizer(x) do x
                        GLib.delboxed(x)
                        #@async println("finalized ",$gstructname)
                    end
                end
                x
            end
            push!(gboxed_types,$gstructname)
        end
    end
    conv=nothing
    if !opaque
        fieldsexpr=Expr[]
        for field in get_fields(structinfo)
            field1=get_name(field)
            type1=extract_type(field).ctype
            push!(fieldsexpr,:($field1::$type1))
        end
        ustruc=quote
            struct $ustructname
                $(fieldsexpr...)
            end
        end
        ustruc=unblock(ustruc)
        push!(exprs,ustruc)
        conv = quote
            unsafe_convert(::Type{Ptr{$ustructname}}, box::$gstructname) = convert(Ptr{$ustructname}, box.handle)
            convert(::Type{$gstructname}, p::Ptr{$ustructname},  owns = false) = $gstructname(p, owns)
        end
    end
    decl = isboxed ? :($gstructname <: GBoxed) : gstructname
    if isboxed
        struc=quote
            mutable struct $decl
                handle::Ptr{$ustructname}
                $fin
            end
        end
    else
        struc=quote
            mutable struct $decl
                handle::Ptr{$ustructname}
            end
        end
    end
    push!(exprs,unblock(struc))
    if conv!==nothing
        push!(exprs,unblock(conv))
    end
    if force_opaque
        ustructname = get_struct_name(structinfo)
        push!(exprs,:(const $ustructname = $gstructname))
    end
    e = quote
        $(exprs...)
    end
    unblock(e)
end

## GObject/GTypeInstance output

function signal_dict(info)
    signals=get_signals(info)
    d=Dict{Symbol,Tuple{Any,Any}}()
    for s in signals
        rettyp = get_ret_type(s)
        argtyps = get_arg_types(s)
        name=Symbol(replace(String(get_name(s)),"-"=>"_"))
        d[name]=(rettyp,argtyps)
    end
    d
end

function signal_dict_incl_parents(objectinfo::GIObjectInfo)
    parentinfo=get_parent(objectinfo)
    if parentinfo!==nothing
        return merge(signal_dict_incl_parents(parentinfo),signal_dict(objectinfo))
    else
        d=Dict{Symbol,Tuple{Any,Any}}()
        d[:notify] = (:Nothing, Any[:(Ptr{GParamSpec})])
        return d
    end
end

get_toplevel(o::GIInterfaceInfo) = :GObject
function get_toplevel(o)
    p = o
    o2 = o
    while p !== nothing
        o2 = p
        p = get_parent(o2)
    end
    o2 !== nothing ? get_type_name(o2) : nothing
end

# For each GObject type GMyObject, we output:
# * an abstract type "GMyObject"
# * a leaf type "GMyObjectLeaf" that has a handle to the C pointer and a
#   constructor that takes a C pointer and "owns" (which controls ref/unref issues)
# * an expression adding this object to the GObject wrapper cache
# * 

function gobject_decl(objectinfo)
    g_type = get_g_type(objectinfo)
    oname = Symbol(GLib.g_type_name(g_type))
    leafname = Symbol(oname,"Leaf")
    parentinfo = get_parent(objectinfo)
    if parentinfo === nothing
        return Expr[]
    end
    pg_type = get_g_type(parentinfo)
    pname = Symbol(GI.GLib.g_type_name(pg_type))

    if oname === :void
        println("get_g_type returns void -- not in library? : ", get_name(objectinfo))
    end
    
    exprs=Expr[]
    decl=quote
        abstract type $oname <: $pname end
        mutable struct $leafname <: $oname
            handle::Ptr{GObject}
            function $leafname(handle::Ptr{GObject}, owns=false)
                if handle == C_NULL
                    error($("Cannot construct $leafname with a NULL pointer"))
                end
                GLib.gobject_maybe_sink(handle,owns)
                return gobject_ref(new(handle))
            end
        end
        gtype_wrapper_cache[$(QuoteNode(oname))] = $leafname
        $(unblock(typeinit_def(objectinfo, oname)))
    end
    push!(exprs, decl)
    # if there are signals, add "signal_return_type" method, and "signal_arg_types" method
    signals = get_all_signals(objectinfo)
    sigdict = signal_dict_incl_parents(objectinfo)
    if length(signals)>0
        signalnames = [Symbol(replace(String(sname),"-"=>"_")) for sname in get_name.(signals)]
        signalexprs = quote
            function GLib.signalnames(::Type{$oname})
                vcat($signalnames,signalnames(supertype($oname)))
            end
            let d = $sigdict
                function GLib.signal_return_type(::Type{T},name::Symbol) where T<:$oname
                    eval(d[name][1])
                end
                function GLib.signal_argument_types(::Type{T},name::Symbol) where T<:$oname
                    Tuple(eval.(d[name][2]))
                end
            end
        end
        push!(exprs,signalexprs)
    else
        signalexprs = quote
            function GLib.signalnames(::Type{$oname})
                signalnames(supertype($oname))
            end
        end
        push!(exprs,signalexprs)
    end
    exprs
end

# For an ObjectInfo, output GObject (or GTypeInstance) stuff, including parent types
function obj_decl!(exprs,o,ns,handled)
    if in(get_name(o),handled)
        return
    end
    p=get_parent(o)
    if p!==nothing && !in(get_name(p),handled) && get_namespace(o) == get_namespace(p)
        obj_decl!(exprs,p,ns,handled)
    end
    if is_gobject(o)
        append!(exprs,unblock(gobject_decl(o)))
    else # for GTypeInstances
        oname = Symbol(GI.get_type_name(o))
        tname = get_toplevel(o)
        leafname = Symbol(oname,"Leaf")
        if p === nothing
            # abstract declaration for toplevel GTypeInstance and convert method
            d=quote
                abstract type $oname <: GTypeInstance end
                Base.convert(::Type{$oname}, ptr::Ptr{$tname}) = $leafname(ptr)
                Base.unsafe_convert(::Type{Ptr{$tname}}, o::$oname) = o.handle
            end
            push!(exprs,d)
        else
            pname = GI.get_type_name(get_parent(o))
            d=quote
                abstract type $oname <: $pname end
            end
            push!(exprs,d)
        end
        d=quote
            mutable struct $leafname <: $oname
                handle::Ptr{$tname}
            end
        end
        push!(exprs,d)
    end
    push!(handled,get_name(o))
end

function decl(interfaceinfo::GIInterfaceInfo)
    g_type = get_g_type(interfaceinfo)
    iname = Symbol(GLib.g_type_name(g_type))

    if iname === :void
        println("get_g_type returns void -- not in library? : ", get_name(interfaceinfo))
    end
    decl=quote
        struct $iname <: GInterface
            handle::Ptr{GObject}
            gc::Any
            $iname(x::GObject) = new(unsafe_convert(Ptr{GObject}, x), x)
        end
    end
    unblock(decl)
end

function get_closure(callbackinfo::GICallbackInfo)
    args = get_args(callbackinfo)
    if length(args) == 0
        return -1
    end
    # this seems very wrong, but they removed the "closure" annotation for callbacks with gobject-introspection 1.76
    if endswith(string(get_name(args[end])),"data") == true
        return length(args)-1
    else
        return -1
    end
end

## Callback output
function decl(callbackinfo::GICallbackInfo)
    name = get_full_name(callbackinfo)
    args=get_args(callbackinfo)
    rettypeinfo=get_return_type(callbackinfo)
    rettype = extract_type(rettypeinfo)
    retexpr = if rettype.ctype == :(Ptr{GObject}) || rettype.ctype == :(Ptr{GVariant}) # not a general solution, but there is not a huge variety of output types
        if get_caller_owns(callbackinfo) == GITransfer.EVERYTHING
            :(ret != C_NULL && GLib.glib_ref(ret);convert($(rettype.ctype),GLib.get_pointer(ret)))
        else
            :(convert($(rettype.ctype),GLib.get_pointer(ret)))
        end
    elseif rettype.ctype == :Nothing
        :(nothing)
    else
        :(convert($(rettype.ctype), ret))
    end
    
    closure = get_closure(callbackinfo)
    if closure == -1
        throw(NotImplementedError("Not implementing callback $name, didn't find a closure"))
    else
        closure_name = get_name(args[closure+1])
    end
    
    input_conversion=[]
    fargs = map(args) do arg
        argname = get_name(arg)
        if argname != closure_name
            typ = extract_type(arg)
            expr = convert_from_c(argname,arg,typ)
            if expr!==nothing
                push!(input_conversion,:($argname = $expr))
            end
        end
        return argname
    end
    d = quote
        function $name($(fargs...))
            $(input_conversion...)
            f = $closure_name
            ret = f($(fargs[1:end-1]...))
            $retexpr
        end
    end
    unblock(d)
end

function get_ret_type(signalinfo::GISignalInfo)
    rettypeinfo=get_return_type(signalinfo)
    extract_type(rettypeinfo).ctype
end

function get_arg_types(signalinfo::GISignalInfo)
    map(get_args(signalinfo)) do arg
        argtype = extract_type(arg)
        argtype.ctype
    end
end

## Signal output
function decl(signalinfo::GISignalInfo, objectinfo=nothing)
    name = get_name(signalinfo)
    fname=Symbol(replace(String(name),"-"=>"_"))
    oname = Symbol("on_$fname")
    rettypefunc = Symbol("$(fname)_signal_return_type")
    typeargsfunc = Symbol("$(fname)_signal_arg_types")
    @assert is_method(signalinfo)
    object = isnothing(objectinfo) ? get_container(signalinfo) : objectinfo
    @assert object !== nothing
    objtypeinfo = extract_type(InstanceType,object)
    rettype = get_ret_type(signalinfo)
    argctypes_arr = get_arg_types(signalinfo)
    argctypes = Expr(:tuple, argctypes_arr...)
    d = quote
        function $oname(f, object::$(objtypeinfo.jtype), user_data=object, after=false)
            GLib.signal_connect_generic(f, object, $(String(name)), $rettype, $argctypes, after, user_data)
        end
    end
    unblock(d)
end

## Handling argument types, creating methods

struct NotImplementedError <: Exception
    message::String
end
NotImplementedError() = NotImplementedError("")

abstract type InstanceType end
is_pointer(::Type{InstanceType}) = true
const TypeInfo = Union{GITypeInfo,Type{InstanceType}}

mutable struct TypeDesc{T}
    gitype::T
    jtype::Union{Expr,Symbol}    # used in Julia for arguments
    jstype::Union{Expr,Symbol}   # most specific relevant Julia type (for properties)
    ctype::Union{Expr,Symbol}    # used in ccall returns and structs
    #catype::Union{Expr,Symbol}   # used in ccall arguments
end

# extract_type creates a TypeDesc corresponding to an argument or field
# for constructing functions and structs
# FIXME: in dire need of cleaning up

# convert_from_c(name,arginfo,typeinfo) produces an expression that sets the symbol "name" from GIArgInfo
# used for certain types to convert returned values from ccall's to Julia types

function extract_type(info::GIArgInfo)
    typdesc = extract_type(get_type(info))
    if may_be_null(info) && typdesc.jtype !== :Any
        jtype=typdesc.jtype
        typdesc.jtype = :(Maybe($jtype))
        typdesc.jstype = :($jtype)
    end
    typdesc
end
extract_type(info::GIFieldInfo) = extract_type(get_type(info))
function extract_type(info::GITypeInfo)
    base_type = get_base_type(info)
    extract_type(info,base_type)
end

function extract_type(info::GITypeInfo, basetype)
    typ = Symbol(string(basetype))
    if is_pointer(info)
        ptyp = :(Ptr{$typ})
        styp = typ
    elseif typ===:Bool
        ptyp = :Cint
        typ = :Bool
        styp = :Bool
    elseif isa(basetype,Type) && basetype <: Integer
        ptyp = typ
        styp = typ
        typ = :Integer
    elseif isa(basetype,Type) && basetype <: Real  # Float64 and Float32
        ptyp = typ
        styp = typ
        typ = :Real
    else
        ptyp = typ
        styp = typ
        typ = :Any
    end
    TypeDesc(basetype,typ,styp,ptyp)
end

#  T<:SomeType likes to steal this:
function extract_type(info::GITypeInfo, basetype::Type{Union{}})
    TypeDesc(Union{}, :Any, :Any, :Nothing)
end

function extract_type(info::GITypeInfo, basetype::Type{String})
    @assert is_pointer(info)
    TypeDesc{Type{String}}(String,:(Union{AbstractString,Symbol}),:String,:(Cstring))
end
function convert_from_c(name::Symbol, arginfo::ArgInfo, typeinfo::TypeDesc{Type{String}})
    owns = get_ownership_transfer(arginfo) != GITransfer.NOTHING
    expr = :( string_or_nothing($name, $owns))
end

function typename(info::GIStructInfo)
    g_type = get_g_type(info)
    if Symbol(GLib.g_type_name(g_type))===:void  # this isn't a GType
        Symbol(get_name(info))
    else
        Symbol(GLib.g_type_name(g_type))
    end
end
function extract_type(typeinfo::GITypeInfo, info::GIStructInfo)
    name = typename(info)
    sname = get_struct_name(info)
    if is_pointer(typeinfo)
        fname = get_full_name(info)
        tname = isopaque(info) ? fname : :(Union{$fname,Ref{$sname}})
        TypeDesc(info,tname,typename(info),:(Ptr{$sname}))
    else
        TypeDesc(info,sname,sname,sname)
    end
end
function extract_type(typeinfo::Type{InstanceType}, info::GIStructInfo)
    name = typename(info)
    sname = get_struct_name(info)
    if is_pointer(typeinfo)
        fname = get_full_name(info)
        tname = isopaque(info) ? fname : :(Union{$fname,Ref{$sname}})
        TypeDesc(info,tname,typename(info),:(Ptr{$sname}))
    else
        TypeDesc(info,sname,sname,sname)
    end
end

function extract_type(typeinfo::GITypeInfo,basetype::Type{T}) where {T<:CEnum.Cenum}
    interf_info = get_interface(typeinfo)
    name = get_name(interf_info)
    TypeDesc{Type{CEnum.Cenum}}(CEnum.Cenum, :Any, name, Symbol(UInt32))
end

function convert_from_c(argname::Symbol, info::ArgInfo, ti::TypeDesc{T}) where {T<:Type{CEnum.Cenum}}
    :( $(ti.jstype)($argname) )
end

function extract_type(typeinfo::GITypeInfo,basetype::Type{T}) where {T<:BitFlags.BitFlag}
    interf_info = get_interface(typeinfo)
    name = get_name(interf_info)
    TypeDesc{Type{BitFlags.BitFlag}}(BitFlags.BitFlag, :Any, name, Symbol(UInt32))
end

function convert_from_c(argname::Symbol, info::ArgInfo, ti::TypeDesc{T}) where {T<:Type{BitFlags.BitFlag}}
    :( $(ti.jstype)($argname) )
end

function convert_to_c(argname::Symbol, info::GIArgInfo, ti::TypeDesc{T}) where {T<:GIEnumOrFlags}
    throw(NotImplementedError("Enum/flags"))
    return (:( enum_get($(enum_name(ti.gitype)),$argname)))
end

function extract_type(typeinfo::GITypeInfo,info::Type{GICArray})
    #@assert is_pointer(typeinfo)
    elm = get_param_type(typeinfo,0)
    elmtype = extract_type(elm)
    elmctype=elmtype.ctype
    TypeDesc{Type{GICArray}}(GICArray,:Any, :(Array{$elmtype}), :(Ptr{$elmctype}))
end
function convert_from_c(name::Symbol, arginfo::ArgInfo, typeinfo::TypeDesc{T}) where {T<:Type{GICArray}}
    if typeof(arginfo)==GIFunctionInfo
        argtypeinfo=get_return_type(arginfo)
    else
        argtypeinfo=get_type(arginfo)
    end
    elm = get_param_type(argtypeinfo,0)
    elmtype = extract_type(elm)
    elmctype=elmtype.ctype
    arrlen=get_array_length(argtypeinfo) # position of array length argument
    lensymb=nothing
    if arrlen != -1
        if typeof(arginfo)==GIFunctionInfo
            args=get_args(arginfo)
        else
            func=get_container(arginfo)
            args=get_args(func)
        end
        lenname=get_name(args[arrlen+1])
        lensymb=Symbol(:m_,lenname)
    end

    owns = typeof(arginfo)==GIFunctionInfo ? get_caller_owns(arginfo) : get_ownership_transfer(arginfo)
    if owns == GITransfer.EVERYTHING  # means it's our responsibility to free both the array and its contents
        if is_zero_terminated(argtypeinfo)
            if elmctype == :(Ptr{UInt8}) || elmctype == :(Cstring)
                return :(_len=length_zt($name);arrtemp=bytestring.(unsafe_wrap(Vector{$elmctype}, $name,_len));GLib.g_strfreev($name);arrtemp)
            else
                throw(NotImplementedError("Zero terminated array that's not strings"))  # TODO
                #:(_len=length_zt($name);arrtemp=copy(unsafe_wrap(Vector{$elmctype}, $name,i-1));GLib.g_free($name);arrtemp)
            end
        else
            if lensymb !== nothing
                if elmctype == :(Ptr{UInt8}) || elmctype == :(Cstring)
                    return :(arrtemp=bytestring.(unsafe_wrap(Vector{$elmctype}, $name, $lensymb[]));GLib.g_free($name);arrtemp)
                else
                    return :(arrtemp=copy(unsafe_wrap(Vector{$elmctype}, $name, $lensymb[]));GLib.g_free($name);arrtemp)
                end
            else
                throw(NotImplementedError("No way to find the length of the output array"))
            end
        end
    elseif owns == GITransfer.CONTAINER # we need to free the array but not the contents
        if lensymb !== nothing
            if elmtype.gitype == GObject
                return :(arrtemp=collect(unsafe_wrap(Vector{$elmctype}, $name,$lensymb[]));GLib.g_free($name);arrtemp=convert.($(elmtype.jtype), arrtemp, false))
            elseif elmctype == :(Ptr{UInt8}) || elmctype == :(Cstring)
                return :(arrtemp=bytestring.(unsafe_wrap(Vector{$elmctype}, $name, $lensymb[]),false);GLib.g_free($name);arrtemp)
            else
                return :(arrtemp=collect(unsafe_wrap(Vector{$elmctype}, $name,$lensymb[]));GLib.g_free($name);arrtemp)
            end
        elseif is_zero_terminated(argtypeinfo)
            throw(NotImplementedError("Zero terminated array, transfer container"))
        else
            throw(NotImplementedError("Transfer container, no length argument"))
        end
    elseif owns == GITransfer.NOTHING # we don't need to free anything (but should we make a copy?)
        if lensymb !== nothing
            if elmctype == :(Ptr{UInt8}) || elmctype == :(Cstring)
                return :(bytestring.(unsafe_wrap(Vector{$elmctype}, $name, $lensymb[])))
            elseif elmtype.gitype == GObject
                return :(arrtemp=collect(unsafe_wrap(Vector{$elmctype}, $name,$lensymb[]));arrtemp=convert.($(elmtype.jtype), arrtemp, false))
            else
                return :(collect(unsafe_wrap(Vector{$elmctype}, $name,$lensymb[])))
            end
        elseif is_zero_terminated(argtypeinfo)
            if elmctype == :(Ptr{UInt8}) || elmctype == :(Cstring)
                return :(_len=length_zt($name);arrtemp=bytestring.(unsafe_wrap(Vector{$elmctype}, $name,_len));arrtemp)
            end
            throw(NotImplementedError("Zero terminated array that's not strings"))
        else  # do nothing here
            return nothing
        end
    end
    throw(NotImplementedError("Unknown array type"))
end

function convert_to_c(name::Symbol, info::GIArgInfo, ti::TypeDesc{T}) where {T<:Type{GICArray}}
    if typeof(info)==GIFunctionInfo
        return (name, nothing)
    end
    is_caller_allocates(info) && throw(NotImplementedException("Array output with 'caller_allocates'"))
    typeinfo=get_type(info)
    elm = get_param_type(typeinfo,0)
    elmtype = extract_type(elm)
    elmctype=elmtype.ctype
    if elmctype == :(Ptr{UInt8}) || elmctype == :(Cstring)
        if may_be_null(info)
            newname = Symbol(name,"_maybe")
            return (newname, :(nothing_to_null($name)))
        end
        return (name, nothing)
    end
    arrname = Symbol(string(name),"_arr")
    (arrname, :(convert(Vector{$elmctype},$name)))
end

function extract_type(typeinfo::GITypeInfo,info::Type{GArray})
    TypeDesc{Type{GArray}}(GArray,:Any, :GArray, :(Ptr{GArray}))
end

function extract_type(typeinfo::GITypeInfo,info::Type{GPtrArray})
    TypeDesc{Type{GPtrArray}}(GPtrArray,:Any, :GPtrArray, :(Ptr{GPtrArray}))
end

function extract_type(typeinfo::GITypeInfo,info::Type{GByteArray})
    TypeDesc{Type{GByteArray}}(GByteArray,:Any, :GByteArray, :(Ptr{GByteArray}))
end

function convert_from_c(name::Symbol, arginfo::ArgInfo, typeinfo::TypeDesc{T}) where {T <: Type{GByteArray}}
    owns = get_ownership_transfer(arginfo) != GITransfer.NOTHING
    if may_be_null(arginfo)
        :(($name == C_NULL ? nothing : convert($(typeinfo.jtype), $name, $owns)))
    else
        :(convert(GByteArray, $name, $owns))
    end
end

function extract_type(typeinfo::GITypeInfo,listtype::Type{T}) where {T<:GLib._LList}
    @assert is_pointer(typeinfo)
    elm = get_param_type(typeinfo,0)
    elmtype = extract_type(elm).ctype
    if elmtype === :(Cstring)
        elmtype = :(String)
    end
    lt = listtype == GLib._GSList ? :(GLib._GSList) : :(GLib._GList)
    TypeDesc{Type{GList}}(GList, :(GLib.LList{$lt{$elmtype}}),:(GLib.LList{$lt{$elmtype}}), :(Ptr{$lt{$elmtype}}))
end
function convert_from_c(name::Symbol, arginfo::ArgInfo, typeinfo::TypeDesc{Type{GList}})
    ot = get_ownership_transfer(arginfo)
    if ot == GITransfer.NOTHING
        :( GLib.GList($name, false, false) )
    elseif ot == GITransfer.CONTAINER
        :( GLib.GList($name, false) )
    elseif ot == GITransfer.EVERYTHING
        :( GLib.GList($name, true) )
    else
        error("Unknown transfer type for GList")
    end
end

function extract_type(typeinfo::GITypeInfo,basetype::Type{Function})
    TypeDesc{Type{Function}}(Function,:Function, :Function, :(Ptr{Cvoid}))
end

callback_symbols(name) = (Symbol("$(name)_cfunc"),Symbol("$(name)_closure"),Symbol("$(name)_notify"))

function convert_to_c(name::Symbol, info::GIArgInfo, ti::TypeDesc{T}) where {T<:Type{Function}}
    st = get_scope(info)
    closure = get_closure(info)
    (st == GIScopeType.FOREVER || st == GIScopeType.INVALID) && throw(NotImplementedError("Scope type $st not implemented."))
    closure == -1 && throw(NotImplementedError("Closure not found."))
    typeinfo=get_type(info)
    callbackinfo=get_interface(typeinfo)
    cclosure = get_closure(callbackinfo)
    # get return type
    rettyp=get_return_type(callbackinfo)
    cname=get_full_name(callbackinfo)
    cfunc, func_closure, func_notify = callback_symbols(name)
    retctyp=extract_type(rettyp).ctype
    # get arg types
    argctypes_arr=[]
    args = get_args(callbackinfo)
    for (i,arg) in enumerate(args)
        if i == length(args) # we already know there is a closure, and it has to be the last argument
            push!(argctypes_arr,:(Ref{Function}))
        else
            argtyp=get_type(arg)
            argctyp=extract_type(argtyp).ctype
            push!(argctypes_arr,argctyp)
        end
    end
    argctypes = Expr(:tuple, argctypes_arr...)
    if st == GIScopeType.CALL # for "call" just create a pointer from a Ref{Function}
                              # and ccall will keep the function around during the call(?)
        closure_expr = quote
            ref = Ref{Any}($name)
            $(func_closure) = unsafe_load(convert(Ptr{Ptr{Nothing}}, Base.unsafe_convert(Ptr{Any}, ref)))
        end
        null_closure_expr = quote
            $(func_closure) = C_NULL
        end
    elseif st == GIScopeType.NOTIFIED # for "notified" follow gc_ref_closure stuff
        closure_expr = quote
            $(func_closure),$(func_notify) = GLib.gc_ref_closure($name)
        end
        null_closure_expr = quote
            $(func_closure) = C_NULL
            $(func_notify) = C_NULL
        end
    elseif st == GIScopeType.ASYNC # for "async" unref after callback finishes?
        # TODO: set up to unref when callback is finished -- currently this leaks
        closure_expr = quote
            $(func_closure) = GLib.gc_ref($name)
        end
        null_closure_expr = quote
            $(func_closure) = C_NULL
        end
    else
        closure_expr = nothing
    end
    closure_expr = unblock(closure_expr)
    null_closure_expr = unblock(null_closure_expr)
    expr = if may_be_null(info)
        quote
            if $name === nothing
                $cfunc = C_NULL
                $(null_closure_expr)
            else
                $cfunc = @cfunction($cname, $retctyp, $argctypes)
                $(closure_expr)
           end
        end
    else
        quote
            $cfunc = @cfunction($cname, $retctyp, $argctypes)
            $(closure_expr)
        end
    end
    # special case: return name symbol, which can be used to find the cfunc and closure names
    name, MacroTools.striplines(unblock(expr))
end

const ObjectLike = Union{GIObjectInfo, GIInterfaceInfo}

typename(info::ObjectLike) = get_type_name(info)

function extract_type(typeinfo::GITypeInfo, basetype::Type{T}) where {T<:GObject}
    interf_info = get_interface(typeinfo)
    name = get_full_name(interf_info)
    TypeDesc{Type{GObject}}(GObject, name, name, :(Ptr{GObject}))
end

function extract_type(typeinfo::GITypeInfo, basetype::Type{T}) where {T<:GInterface}
    interf_info = get_interface(typeinfo)
    obj = get_gobj_prerequisite(interf_info)
    name = get_full_name(interf_info)
    TypeDesc{Type{GInterface}}(GInterface, name, name, :(Ptr{$obj}))
end

function extract_type(typeinfo::GITypeInfo, basetype::Type{T}) where {T<:GBoxed}
    interf_info = get_interface(typeinfo)
    name = get_full_name(interf_info)
    sname = get_struct_name(interf_info)
    p = is_pointer(typeinfo)
    jarg = (name != sname ? :(Union{$name,Ref{$sname}}) : name)
    ctype = is_pointer(typeinfo) ? :(Ptr{$sname}) : sname
    TypeDesc{Type{GBoxed}}(GBoxed, jarg, name, ctype)
end

function _convert_obj_to_c(name::Symbol, arginfo::GIArgInfo, typeinfo)
    if may_be_null(arginfo)
        if get_ownership_transfer(arginfo) == GITransfer.EVERYTHING
            newname = Symbol(name,"_maybe")
            exprs = quote
                if $name !== nothing
                    GLib.glib_ref($name)
                end
                nothing_to_null($name)
            end
            return (newname, exprs)
        else
            newname = Symbol(name,"_maybe")
            return (newname, :(nothing_to_null($name)))
        end
    else
        if get_ownership_transfer(arginfo) == GITransfer.EVERYTHING
            return (name, :(GLib.glib_ref($name)))
        end
    end
    (name, nothing)
end

function convert_to_c(name::Symbol, arginfo::GIArgInfo, typeinfo::TypeDesc{T}) where {T<:Type{GObject}}
    _convert_obj_to_c(name,arginfo,typeinfo)
end

function convert_to_c(name::Symbol, arginfo::GIArgInfo, typeinfo::TypeDesc{T}) where {T<:Type{GInterface}}
    _convert_obj_to_c(name,arginfo,typeinfo)
end

function convert_from_c(name::Symbol, arginfo::ArgInfo, typeinfo::TypeDesc{T}, isconstructor=false) where {T <: Type{GObject}}
    owns = get_ownership_transfer(arginfo) != GITransfer.NOTHING
    object = get_container(arginfo)
    if may_be_null(arginfo)
        :(convert_if_not_null($(typeinfo.jstype), $name, $owns))
    elseif isconstructor && !get_abstract(object)
        # For a constructor, we know this is a never-before-seen object, so use the known concrete type to allow type inference
        # Many of these have an abstract type as the return type in GI, but we need the
        # concrete one. Since this is a constructor we can look up the name.
        objname = get_full_name(object)
        leaftype = Symbol("$(objname)Leaf")
        :($leaftype($name, $owns))
    else
        :(convert($(typeinfo.jtype), $name, $owns))
    end
end

function convert_from_c(name::Symbol, arginfo::ArgInfo, typeinfo::TypeDesc{T}) where {T <: Type{GInterface}}
    owns = get_ownership_transfer(arginfo) != GITransfer.NOTHING
    if may_be_null(arginfo)
        :(GLib.find_leaf_type_if_not_null($name, $owns))
    else
        :(leaftype = GLib.find_leaf_type($name);convert(leaftype, $name, $owns))
    end
end

function convert_from_c(name::Symbol, arginfo::ArgInfo, typeinfo::TypeDesc{T}) where {T <: Type{GBoxed}}
    owns = get_ownership_transfer(arginfo) != GITransfer.NOTHING
    typ = isa(arginfo, GIFunctionInfo) ? 0 : get_type(arginfo)

    if may_be_null(arginfo)
        :(convert_if_not_null($(typeinfo.jstype), $name, $owns))
    elseif typ == 0 || (typ != 0 && is_pointer(typ))
        :(convert($(typeinfo.jtype), $name, $owns))
    end
end

# avoid method ambiguity
function extract_type(typeinfo::GITypeInfo, info::ObjectLike)
    if is_pointer(typeinfo)
        if typename(info)===:GParam  # GParamSpec is a GTypeInstance but we handle it differently
            throw(NotImplementedError("ObjectLike but not a GObject"))
            #return TypeDesc(info,:GParamSpec,:(Ptr{GParamSpec}))
        end
        t = get_toplevel(info)
        TypeDesc(info,typename(info),typename(info),:(Ptr{$t}))
    else
        # a GList has implicitly pointers to all elements
        TypeDesc(info,:INVALID,:INVALID,:GObject)
    end
end
function extract_type(typeinfo::Type{InstanceType}, info::ObjectLike)
    if is_pointer(typeinfo)
        if typename(info)===:GParam  # GParamSpec is a GTypeInstance but we handle it differently
            throw(NotImplementedError("ObjectLike but not a GObject"))
            #return TypeDesc(info,:GParamSpec,:(Ptr{GParamSpec}))
        end
        t = get_toplevel(info)
        TypeDesc(info,typename(info),typename(info),:(Ptr{$t}))
    else
        # a GList has implicitly pointers to all elements
        TypeDesc(info,:INVALID,:INVALID,:GObject)
    end
end

"""
    convert_to_c(argname, arginfo, typeinfo) => name, expr

Produces an expression that converts a Julia input to something `ccall` can use as an argument, along with
a new name. If no translation is necessary, (argname, nothing) will be returned.

This function is expected to handle arguments that may be nothing by possibly converting them to C_NULL.
"""
function convert_to_c(name::Symbol, info::GIArgInfo, ti::TypeDesc)
    if may_be_null(info)
        newname = Symbol(name,"_maybe")
        return (newname, :(nothing_to_null($name)))
    end
    (name, nothing)
end

function convert_from_c(name::Symbol, arginfo::ArgInfo, ti::TypeDesc{T}) where {T}
    # check transfer
    typ=get_type(arginfo)

    if ti.jtype !== :Any && ti.jtype !== :Real && ti.jtype !== :Integer
        :(convert($(ti.jtype), $name))
    elseif ti.gitype === Bool
        :(convert(Bool, $name))
    else
        nothing
    end
end

function extract_type(typeinfo::GITypeInfo,info::Type{GError})
    TypeDesc{Type{GError}}(GError,:Any, :GError, :(Ptr{GError}))
end

function extract_type(typeinfo::GITypeInfo,info::Type{GHashTable})
    TypeDesc{Type{GHashTable}}(GHashTable,:Any, :GHashTable, :(Ptr{GHashTable}))
end

struct Arg
    name::Symbol
    typ::Union{Expr,Symbol}
end
types(args::Array{Arg}) = [a.typ for a in args]
names(args::Array{Arg}) = [a.name for a in args]
function jparams(args::Array{Arg})
    [a.typ !== :Any ? :($(a.name)::$(a.typ)) : a.name for a in args]
end

# Map library names onto exports of *_jll
const libnames = Dict("libglib"=>:libglib, "libgobject"=>:libgobject,
                "libgio"=>:libgio, "libcairo-gobject"=>:libcairo_gobject,
                "libpangocairo"=>:libpangocairo, "libpangoft"=>:libpangoft,
                "libpango"=>:libpango, "libatk"=>:libatk,
                "libgdk_pixbuf"=>:libgdkpixbuf, "libgdk-3"=>:libgdk3,
                "libgtk-3"=>:libgtk3, "libgraphene"=>:libgraphene,
                 "libgtk-4"=>:libgtk4, "libaravis"=>:libaravis,
                 "libadwaita"=>:libadwaita, "libgtksourceview-5"=>:libgtksourceview)
function symbol_from_lib(libname)
    ks = collect(keys(libnames))
    k=findfirst(n->occursin(n, libname), ks)
    isnothing(k) ? libname : libnames[ks[k]]
end

function make_ccall(slib::Union{String,Symbol}, id, rtype, args)
    argtypes = Expr(:tuple, types(args)...)
    c_call = :(ccall(($id, $slib), $rtype, $argtypes))
    append!(c_call.args, names(args))
    c_call
end

function make_ccall(libs::AbstractArray, id, rtype, args)
    # look up symbol in our possible libraries
    s=findfirst(find_symbol(id),libs)
    s === nothing && error("can't find $id in libs")
    lib=libs[s]
    slib=symbol_from_lib(lib)
    make_ccall(slib, id, rtype, args)
end

function get_constructors(info::Union{GIStructInfo,GIObjectInfo};skiplist=Symbol[],struct_skiplist=Symbol[],exclude_deprecated=true)
    methods=get_methods(info)
    name=get_name(info)
    nsstring=get_namespace(info)
    sname=Symbol("G_.",name)
    tname=get_type_name(info)
    outs=Expr[]
    gskiplist=[Symbol(nsstring,i) for i in struct_skiplist]
    ugskiplist=[Symbol("_",nsstring,i) for i in struct_skiplist]
    for minfo in methods
        if (exclude_deprecated && is_deprecated(minfo)) || get_name(minfo) in skiplist
            continue
        end
        if get_flags(minfo) & GIFunction.IS_CONSTRUCTOR != 0
            jargs = get_jargs(minfo)
            bad = false
            for argtyp in types(jargs)
                if (argtyp in gskiplist) || (argtyp in ugskiplist)
                    bad=true
                end
            end
            if bad
                continue
            end
            mname = constructor_name(minfo, get_name(minfo))
            fun = if isa(info, GIObjectInfo) && length(get_properties(info))>0
                quote
                    function $tname($(jparams(jargs)...); kwargs...)
                        obj = G_.$mname($(names(jargs)...))
                        GLib.setproperties!(obj; kwargs...)
                        obj
                    end
                end
            else
                quote
                    function $tname($(jparams(jargs)...))
                        G_.$mname($(names(jargs)...))
                    end
                end
            end

            push!(outs,unblock(fun))
        end
    end
    outs
end

function get_closure_args(info::GIFunctionInfo)
    closure_args=Dict{Symbol,Int}()
    for arg in get_args(info)
        is_skip(arg) && continue
        typ = extract_type(arg)
        closure = get_closure(arg)
        if typ.gitype == Function && closure > -1
            aname = Symbol("_", get_name(arg))
            closure_args[aname]=closure+1
        end
    end
    closure_args
end

function get_jargs(info::GIFunctionInfo)
    flags = get_flags(info)
    args = get_args(info)
    jargs = Arg[]
    if flags & GIFunction.IS_METHOD != 0
        object = get_container(info)
        if object !== nothing
            typeinfo = extract_type(InstanceType,object)
            push!(jargs, Arg(:instance, typeinfo.jtype))
        end
    end
    # go through args and find the closure arguments for each function argument
    closure_args=get_closure_args(info)
    for (iarg,arg) in enumerate(args)
        is_skip(arg) && continue
        aname = Symbol("_$(get_name(arg))")
        typ = extract_type(arg)
        dir = get_direction(arg)
        if dir != GIDirection.OUT
            !(iarg in values(closure_args)) && push!(jargs, Arg( aname, typ.jtype))
        end
    end

    # go through args again, remove length jargs for array inputs
    for arg in args
        is_skip(arg) && continue
        typ = extract_type(arg)
        typeinfo=get_type(arg)
        arrlen=get_array_length(typeinfo)
        if typ.gitype == GICArray && arrlen >= 0
            len_name=Symbol("_",get_name(args[arrlen+1]))
            len_i=findfirst(a->(a.name === len_name),jargs)
            len_i !== nothing && deleteat!(jargs,len_i)
        end
    end
    jargs
end

function constructor_name(info, mname)
    object = get_container(info)
    object !== nothing ? Symbol("$(get_name(object))_$mname") : mname
end

function create_interface_method(info::GIFunctionInfo, obj::GIObjectInfo, liboverride = nothing)
    name = get_name(info)
    flags = get_flags(info)
    if flags & GIFunction.IS_METHOD == 0
        return nothing
    end
    ms = get_methods(obj)
    if findfirst(m->get_name(m)==name, ms) !== nothing  # there is a conflicting object method
        return nothing
    end
    jargs = get_jargs(info)
    jargsp = copy(jargs)
    typeinfo = extract_type(InstanceType,obj)
    # replace the first argument of the definition with our object
    jargsp[1] = Arg(:instance, typeinfo.jtype)
    # replace the first argument of the call
    callargs = Any[n for n in names(jargs)]
    ifacename = get_full_name(get_container(info))
    callargs[1] = :($ifacename($(callargs[1])))
    j_call = Expr(:call, name, jparams(jargsp)... )
    blk = quote
        $name($(callargs...))
    end
    Expr(:function, j_call, blk)
end

# with some partial-evaluation half-magic
# (or maybe just jit-compile-time macros)
# this could be simplified significantly
function create_method(info::GIFunctionInfo, liboverride = nothing)
    name = get_name(info)
    flags = get_flags(info)
    args = get_args(info)
    prologue = Any[]
    epilogue = Any[]
    retvals = Symbol[]
    cargs = Arg[]
    jargs = get_jargs(info)
    if flags & GIFunction.IS_METHOD != 0
        object = get_container(info)
        if object !== nothing
            typeinfo = extract_type(InstanceType,object)
            push!(cargs, Arg(:instance, typeinfo.ctype))
        end
    end
    if flags & GIFunction.IS_CONSTRUCTOR != 0
        name = constructor_name(info, name)
    end
    rettypeinfo=get_return_type(info)
    rettype = extract_type(rettypeinfo)
    if rettype.ctype !== :Nothing && !skip_return(info)
        expr = if flags & GIFunction.IS_CONSTRUCTOR != 0 && rettype.gitype == GObject
            convert_from_c(:ret,info,rettype,true)
        else
            convert_from_c(:ret,info,rettype)
        end
        if expr !== nothing
            push!(epilogue, :(ret2 = $expr))
            push!(retvals,:ret2)
        else
            push!(retvals,:ret)
        end
    end
    # go through args and find the closure arguments for each function argument
    closure_args=get_closure_args(info)
    for (iarg,arg) in enumerate(args)
        is_skip(arg) && continue
        aname = Symbol("_$(get_name(arg))")
        typ = extract_type(arg)
        dir = get_direction(arg)
        anametran = aname
        if dir != GIDirection.OUT
            anametran, expr = convert_to_c(aname,arg,typ)
            if expr !== nothing && !(iarg in values(closure_args))
                if typ.gitype == Function
                    push!(prologue, expr)
                else
                    push!(prologue, :($anametran = $expr))
                end
            end
        end

        if dir == GIDirection.IN
            if typ.gitype == Function
                cfuncname, closurename, notifyname = callback_symbols(anametran)
                push!(cargs, Arg(cfuncname, typ.ctype))
                if haskey(closure_args, anametran)
                    push!(cargs, Arg(closurename, :(Ptr{Nothing})))
                end
            elseif !(iarg in values(closure_args))
                push!(cargs, Arg(anametran, typ.ctype))
            end
        else
            ctype = typ.ctype
            wname = Symbol("m_$(get_name(arg))")
            atyp = get_type(arg)
            push!(prologue, :( $wname = Ref{$ctype}() ))
            if dir == GIDirection.INOUT
                push!(prologue, :( $wname[] = Base.cconvert($ctype,$anametran) ))
            end
            push!(cargs, Arg(wname, :(Ptr{$ctype})))
            push!(epilogue,:( $anametran = $wname[] ))
            expr = convert_from_c(anametran,arg,typ)
            if expr !== nothing
                push!(epilogue, :($anametran = $expr))
            end
            push!(retvals, anametran)
        end
    end

    # go through args again, remove length jargs for array inputs, add call
    # to length() to prologue
    for arg in args
        is_skip(arg) && continue
        typ = extract_type(arg)
        aname = Symbol("_$(get_name(arg))")
        typeinfo=get_type(arg)
        arrlen=get_array_length(typeinfo)
        if typ.gitype == GICArray && arrlen >= 0
            len_name=Symbol("_",get_name(args[arrlen+1]))
            len_i=findfirst(a->((Symbol("_$(get_name(a))") === len_name && get_direction(a) != GIDirection.OUT)),args)
            if len_i !== nothing
                push!(prologue, :($len_name = length($aname)))
            end
            len_i=findfirst(==(len_name),retvals)
            len_i !== nothing && deleteat!(retvals,len_i)
        end
    end
    if rettype.gitype == GICArray
        arrlen=get_array_length(rettypeinfo)
        if arrlen >=0
            len_name=Symbol("_",get_name(args[arrlen+1]))
            len_i=findfirst(==(len_name),retvals)
            len_i !== nothing && deleteat!(retvals,len_i)
        end
    end

    if flags & GIFunction.THROWS != 0
        push!(prologue, :( err = err_buf() ))
        push!(cargs, Arg(:err, :(Ptr{Ptr{GError}})))
        pushfirst!(epilogue, :( check_err(err) ))
    end

    symb = get_symbol(info)
    j_call = Expr(:call, name, jparams(jargs)... )
    if liboverride === nothing
        libs=get_shlibs(GINamespace(get_namespace(info)))
        c_call = :( ret = $(make_ccall(libs, string(symb), rettype.ctype, cargs)))
    else
        c_call = :( ret = $(make_ccall(liboverride, string(symb), rettype.ctype, cargs)))
    end
    if length(retvals) > 1
        retstmt = Expr(:tuple, retvals...)
    elseif length(retvals) ==1
        retstmt = retvals[]
    else
        retstmt = :nothing
    end
    blk = Expr(:block)
    blk.args = vcat(prologue, c_call, epilogue, retstmt )
    fun = Expr(:function, j_call, blk)
end
