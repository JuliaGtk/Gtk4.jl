# use libgirepository to produce Julia declarations and methods

const_decls(ns) = const_decls(ns,x->x)
function const_decls(ns,fmt)
    consts = get_consts(ns)
    decs = Expr[]
    for (name,val) in consts
        name = fmt(name)
        if name !== nothing
            push!(decs, :(const $(Symbol(name)) = $(val)) )
        end
    end
    decs
end
const_expr(name,val) =  :($(Symbol(name)) = $(val))

# export enum using a baremodule, as is done in Gtk.jl
function enum_decl(enum)
    enumname=get_name(enum)
    vals = get_enum_values(enum)
    body = Expr(:block)
    for (name,val) in vals
        if match(r"^[a-zA-Z_]",string(name)) === nothing
            name = Symbol("_$name")
        end
        push!(body.args, :(const $(uppercase(name)) = $val) )
    end
    Expr(:toplevel,Expr(:module, false, Symbol(enumname), body))
end

enum_fullname(enumname,name) = Symbol(enumname,"_",uppercase(name))

# export as a Julia enum type
function enum_decl2(enum)
    enumname=get_name(enum)
    vals = get_enum_values(enum)
    typ = typetag_primitive[get_storage_type(enum)]
    body = Expr(:macrocall)
    push!(body.args, Symbol("@cenum"))
    push!(body.args, Symbol("nothing"))
    push!(body.args, :($enumname::$typ))
    for (name,val) in vals
        val=unsafe_trunc(typ,val)  # sometimes the value returned by GI is outside the range of the enum's type
        fullname=enum_fullname(enumname,name)
        push!(body.args, :($fullname = $val) )
    end
    bloc = Expr(:block)
    push!(bloc.args,body)
    bloc
end

function enum_decls(ns)
    enums = get_all(ns, GIEnumOrFlags)
    typedefs = Expr[]
    aliases = Expr[]
    for enum in enums
        name = get_name(enum)
        longname = enum_name(enum)
        push!(typedefs,enum_decl(enum,name))
        push!(aliases, :( const $name = _AllTypes.$longname))
    end
    (typedefs,aliases)
end
enum_name(enum) = Symbol(string(get_namespace(enum),get_name(enum)))

## Struct output

# Opaque structs (where the contents are not part of the public API) are
# exported with a "handle" field.

# Non-opaque structs can be outputted too but details are still being worked out

# get the thing that should go inside the curly brackets in Ptr{}
function get_struct_name(structinfo,force_opaque=false)
    fields=get_fields(structinfo)
    gstructname = get_full_name(structinfo)
    (length(fields)>0 && !force_opaque) ? Symbol("_",gstructname) : gstructname
end

function struct_decl(structinfo;force_opaque=false)
    fields=get_fields(structinfo)
    gstructname = get_full_name(structinfo)
    ustructname=get_struct_name(structinfo,force_opaque)
    gtype=get_g_type(structinfo)
    isboxed = GLib.g_isa(gtype,GLib.g_type_from_name(:GBoxed))
    opaque = length(fields)==0 || force_opaque
    decl = isboxed ? :($gstructname <: GBoxed) : gstructname
    exprs=Expr[]
    if isboxed
        type_init = String(get_type_init(structinfo))
        libs=get_shlibs(GINamespace(get_namespace(structinfo)))
        lib=libs[findfirst(l->(nothing!=dlsym(dlopen(l),type_init)),libs)]
        slib=symbol_from_lib(lib)
        fin = quote
            GLib.g_type(::Type{T}) where {T <: $gstructname} =
                      ccall(($type_init, $slib), GType, ())
            function $gstructname(ref::Ptr{T}, own::Bool = false) where {T <: GBoxed}
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
    fieldgetter=nothing
    if !opaque
        fieldsexpr=Expr[]
        for field in fields
            field1=get_name(field)
            type1=extract_type(field).ctype
            push!(fieldsexpr,:($field1::$type1))
        end
        ustructname=Symbol("_",gstructname)
        ustruc=quote
            struct $ustructname
                $(fieldsexpr...)
            end
        end
        # fieldgetter=quote
        #     unsafe_convert(::Type{Ptr{$ustructname}}, box::$gstructname) = convert(Ptr{$ustructname}, box.handle)
        #     function Base.getproperty(s::$gstructname,sym::Symbol)
        #         if sym===:handle
        #             return getfield(s,:handle)
        #         elseif in(sym,fieldnames($ustructname))
        #             u=unsafe_load(Ptr{$ustructname}(s.handle))
        #             return getfield(u,sym)
        #         end
        #     end
        # end
        ustruc=unblock(ustruc)
        fieldgetter=unblock(fieldgetter)
        push!(exprs,ustruc)
    end
    if isboxed
        struc=quote
            mutable struct $decl
                handle::Ptr{$ustructname}
                $fin
            end
            #$fieldgetter
        end
    else
        struc=quote
            mutable struct $decl
                handle::Ptr{$ustructname}
            end
            #$fieldgetter
        end
    end
    push!(exprs,struc)
    if force_opaque
        ustructname = get_struct_name(structinfo)
        push!(exprs,:(const $ustructname = $gstructname))
    end
    e = quote
        $(exprs...)
    end
    unblock(e)
end

## GObject output (simpler in some ways than type declaration macros in Gtk.GLib)
# NOTE: These are not currently used (see below for code that uses the Gtk.jl macros)
# Leaving these here for possible future use

# extract properties for a particular GObject type
function prop_dict(info)
    properties=get_properties(info)
    d=Dict{Symbol,Tuple{Any,Int32,Int32}}()
    for p in properties
        # whether the property is readable, writable, other stuff
        flags=get_flags(p)

        # in practice it looks like this is never set to anything but TRANSFER_NONE, so we could omit it
        tran=get_ownership_transfer(p)

        typ=get_type(p)
        btyp=get_base_type(typ)
        ptyp=extract_type(typ,btyp)
        name=Symbol(replace(String(get_name(p)),"-"=>"_"))
        d[name]=(ptyp.jstype,tran,flags)
    end
    d
end

# extract properties for a particular GObject type and all its parents
function prop_dict_incl_parents(objectinfo::GIObjectInfo)
    d=prop_dict(objectinfo)
    parentinfo=get_parent(objectinfo)
    if parentinfo!==nothing
        return merge(prop_dict_incl_parents(parentinfo),d)
    else
        return d
    end
end

# For each GObject type GMyObject, we output:
# * an abstract type "GMyObject"
# * a leaf type "GMyObjectLeaf" that has a handle to the C pointer and a
#   constructor that takes a C pointer
# * a constructor for the leaf type that takes key word arguments, for
#   constructing an object with particular property values
# * a key word constructor for the abstract type that calls the constructor just
#   mentioned
# * an expression adding this object to the GObject wrapper cache
# * if there are properties, we construct a dictionary of the properties of this
#   type and its interfaces with information

function gobject_decl(objectinfo)
    g_type = get_g_type(objectinfo)
    oname = Symbol(GLib.g_type_name(g_type))
    leafname = Symbol(oname,"Leaf")
    parentinfo = get_parent(objectinfo)
    pg_type = get_g_type(parentinfo)
    pname = Symbol(GI.GLib.g_type_name(pg_type))

    # property info
    d=prop_dict_incl_parents(objectinfo)
    for i in get_interfaces(objectinfo)
        di=prop_dict(i)
        d=merge(di,d)
    end
    READABLE   = 0x00000001
    WRITABLE   = 0x00000002
    rd=filter((p->p.second[3] & READABLE!=0),d)
    wd=filter((p->p.second[3] & WRITABLE!=0),d)
    propnames=vcat([:handle],collect(keys(d)))
    propexprs=Expr[]
    if length(d)>0
        propexpr=quote
            Base.propertynames(o::$leafname) = $propnames
            function Base.getproperty(o::$leafname,name::Symbol)
                d=$rd
                if in(name,keys(d))
                    return get_gtk_property(o,name,eval(d[name][1]))
                else
                    return getfield(o,name)
                end
            end
            function Base.setproperty!(o::$leafname,name::Symbol,x)
                d=$wd
                if in(name,keys(d))
                    set_gtk_property!(o,name,x)
                else
                    setfield!(o,name,x)
                end
            end
        end
        push!(propexprs,propexpr)
    end

    decl=quote
        abstract type $oname <: $pname end
    end
    exprs=Expr[]
    push!(exprs,decl)
    decl=quote
        mutable struct $leafname <: $oname
            handle::Ptr{GObject}
            function $leafname(handle::Ptr{GObject}, owns=false)
                if handle == C_NULL
                    error($("Cannot construct $leafname with a NULL pointer"))
                end
                is_floating = (ccall(("g_object_is_floating", libgobject), Cint, (Ptr{GObject},), handle)!=0)
                if !owns || is_floating # if owns is true then we already have a reference, but if it's floating we should sink it
                    gc_ref_sink(handle)
                end
                return gobject_ref(new(handle))
            end
        end
        local kwargs
        function $leafname(args...; kwargs...)
            if isempty(kwargs)
                error(MethodError($leafname, args))
            end
            w = $leafname(args...)
            for (kw, val) in kwargs
                set_gtk_property!(w, kw, val)
            end
            w
        end
        gtype_wrapper_cache[$(QuoteNode(oname))] = $leafname
        function $oname(args...; kwargs...)
            $leafname(args...; kwargs...)
        end
        $(propexprs...)
    end
    push!(exprs, decl)
    exprs
end

# For an ObjectInfo, output GObject stuff, including parent types
function obj_decl!(exprs,o,ns,handled)
    if in(get_name(o),handled)
        return
    end
    p=get_parent(o)
    if p!==nothing && !in(get_name(p),handled) && get_namespace(o) == get_namespace(p)
        obj_decl!(exprs,p,ns,handled)
    end
    append!(exprs,gobject_decl(o))
    push!(handled,get_name(o))
end

function ginterface_decl(interfaceinfo)
    g_type = get_g_type(interfaceinfo)
    iname = Symbol(GLib.g_type_name(g_type))
    decl=quote
        struct $iname <: GInterface
            handle::Ptr{GObject}
            gc::Any
            $iname(x::GObject) = new(unsafe_convert(Ptr{GObject}, x), x)
        end
    end
    exprs=Expr[]
    push!(exprs,decl)
    exprs
end

## Output GObject and GInterface declarations using macros in Gtk.GLib

function gen_macro(info, m)
    body = Expr(:macrocall)
    push!(body.args, Symbol(m))
    push!(body.args, Symbol("nothing"))
    push!(body.args, get_full_name(info))
    libs=get_shlibs(GINamespace(get_namespace(info)))
    type_init = String(get_type_init(info))
    lib=libs[findfirst(l->(nothing!=dlsym(dlopen(l),type_init)),libs)]
    push!(body.args, symbol_from_lib(lib))
    push!(body.args, Symbol(chop(type_init,tail=9))) # remove "_get_type"
    body
end

# For an ObjectInfo, output a macro declaration
obj_macro(o) = gen_macro(o,"@Gtype")
interface_macro(i) = gen_macro(i,"@Giface")

## Handling argument types, creating methods

mutable struct NotImplementedError <: Exception
end

abstract type InstanceType end
is_pointer(::Type{InstanceType}) = true
const TypeInfo = Union{GITypeInfo,Type{InstanceType}}

struct TypeDesc{T}
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

# convert_to_c(argname, arginfo, typeinfo) produces an expression that converts
# a Julia input to something a ccall can use as an argument

function extract_type(info::GIArgInfo)
    typdesc = extract_type(get_type(info))
    if may_be_null(info) && typdesc.jtype !== :Any
        jtype=typdesc.jtype
        typdesc = TypeDesc(typdesc.gitype, :(Maybe($jtype)), typdesc.jstype, typdesc.ctype)
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
    expr = :( ($name == C_NULL) ? nothing : bytestring($name, $owns))
end

function typename(info::GIStructInfo)
    g_type = get_g_type(info)
    if Symbol(GLib.g_type_name(g_type))===:void  # this isn't a GType
        Symbol(get_name(info))
    else
        Symbol(GLib.g_type_name(g_type))
    end
end
function extract_type(typeinfo::TypeInfo, info::GIStructInfo)
    name = typename(info)
    sname = get_struct_name(info)
    if is_pointer(typeinfo)
        #TypeDesc(info,:(Ptr{$name}),:(Ptr{$name})) # use this for plain old structs?
        TypeDesc(info,typename(info),typename(info),:(Ptr{$sname}))
        #TypeDesc(info,:Any,:(Ptr{Nothing}))
    else
        TypeDesc(info,name,name,name)
    end
end

function extract_type(typeinfo::GITypeInfo,basetype::Type{T}) where {T<:Enum}
    bt=Base.Enums.basetype(T)
    interf_info = get_interface(typeinfo)
    name = get_name(interf_info)
    TypeDesc{Type{Enum}}(Enum, :Any, name, Symbol(bt))
end

function convert_from_c(argname::Symbol, info::ArgInfo, ti::TypeDesc{T}) where {T<:Type{Enum}}
    :( $(ti.jstype)($argname) )
end

function convert_to_c(argname::Symbol, info::GIArgInfo, ti::TypeDesc{T}) where {T<:GIEnumOrFlags}
    :( enum_get($(enum_name(ti.gitype)),$argname) )
end

function extract_type(typeinfo::GITypeInfo,info::Type{GICArray})
    @assert is_pointer(typeinfo)
    elm = get_param_type(typeinfo,0)
    elmtype = extract_type(elm)
    elmctype=elmtype.ctype
    elmgitype=elmtype.gitype
    elmjtype=elmtype.jtype
    #TypeDesc{Type{GICArray}}(GICArray,:(Vector{$elmgitype}), :(Ptr{$elmctype}))
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
    arrlen=get_array_length(argtypeinfo)
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
    if is_zero_terminated(argtypeinfo) && owns==GITransfer.EVERYTHING
        if elmctype == :(Ptr{UInt8}) || elmctype == :(Cstring)
            :(_len=length_zt($name);ret2=bytestring.(unsafe_wrap(Vector{$elmctype}, $name,_len));GLib.g_strfreev($name);ret2)
        else
            return nothing
            #:(_len=length_zt($name);ret2=copy(unsafe_wrap(Vector{$elmctype}, $name,i-1));GLib.g_free($name);ret2)
        end
    elseif owns==GITransfer.CONTAINER && lensymb != nothing
        if elmtype.gitype == GObject
            :(ret2=copy(unsafe_wrap(Vector{$elmctype}, $name,$lensymb[]));GLib.g_free($name);ret2=convert.($(elmtype.jtype), ret2, false))
        else
            :(ret2=copy(unsafe_wrap(Vector{$elmctype}, $name,$lensymb[]));GLib.g_free($name);ret2)
        end
    else
        #throw(NotImplementedError)
        return nothing
    end
end

function convert_to_c(name::Symbol, info::GIArgInfo, ti::TypeDesc{T}) where {T<:Type{GICArray}}
    if typeof(info)==GIFunctionInfo
        return nothing
    end
    typeinfo=get_type(info)
    elm = get_param_type(typeinfo,0)
    elmtype = extract_type(elm)
    elmctype=elmtype.ctype
    if elmctype == :(Ptr{UInt8}) || elmctype == :(Cstring)
        return nothing
    end
    :(convert(Vector{$elmctype},$name))
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
    lt = listtype == GLib._GSList ? :(GLib._GSList) : :(GLib._GList)
    TypeDesc{Type{GList}}(GList, :(GLib.LList{$lt{$elmtype}}),:(GLib.LList{$lt{$elmtype}}), :(Ptr{$lt{$elmtype}}))
end
function convert_from_c(name::Symbol, arginfo::ArgInfo, typeinfo::TypeDesc{Type{GList}})
    owns = (get_ownership_transfer(arginfo) == GITransfer.EVERYTHING)
    if get_ownership_transfer(arginfo) == GITransfer.NOTHING
          nothing  # just return the pointer
    else
        :( GLib.GList($name, $owns) )
    end
end

function extract_type(typeinfo::GITypeInfo,basetype::Type{Function})
    TypeDesc{Type{Function}}(Function,:Function, :Function, :(Ptr{Nothing}))
end

function convert_to_c(name::Symbol, info::GIArgInfo, ti::TypeDesc{T}) where {T<:Type{Function}}
    throw(NotImplementedError)
    typeinfo=get_type(info)
    callbackinfo=get_interface(typeinfo)
    #println(get_name(callbackinfo))
    # get return type
    rettyp=get_return_type(callbackinfo)
    retctyp=extract_type(rettyp).ctype
    # get arg types
    argctypes_arr=[]
    for arg in get_args(callbackinfo)
        argtyp=get_type(arg)
        argctyp=extract_type(argtyp).ctype
        push!(argctypes_arr,argctyp)
    end
    argctypes = Expr(:tuple, argctypes_arr...)
    special=QuoteNode(Expr(:$, :name))
    expr = quote
        @cfunction($special, $retctyp, $argctypes)
    end
    MacroTools.striplines(expr)
end

const ObjectLike = Union{GIObjectInfo, GIInterfaceInfo}

function typename(info::ObjectLike)
    g_type = get_g_type(info)
    Symbol(GLib.g_type_name(g_type))
end

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
    ctype = is_pointer(typeinfo) ? :(Ptr{$sname}) : sname
    TypeDesc{Type{GBoxed}}(GBoxed, name, name, ctype)
end

function convert_from_c(name::Symbol, arginfo::ArgInfo, typeinfo::TypeDesc{T}) where {T <: Type{GObject}}
    owns = get_ownership_transfer(arginfo) != GITransfer.NOTHING
    if may_be_null(arginfo)
        :(($name == C_NULL ? nothing : convert($(typeinfo.jtype), $name, $owns)))
    else
        :(convert($(typeinfo.jtype), $name, $owns))
    end
end

function convert_from_c(name::Symbol, arginfo::ArgInfo, typeinfo::TypeDesc{T}) where {T <: Type{GInterface}}
    owns = get_ownership_transfer(arginfo) != GITransfer.NOTHING
    if may_be_null(arginfo)
        quote
            if $name == C_NULL
                nothing
            else
                leaftype = GLib.find_leaf_type($name)
                convert(leaftype, $name, $owns)
            end
        end
    else
        :(leaftype = GLib.find_leaf_type($name);convert(leaftype, $name, $owns))
    end
end

function convert_from_c(name::Symbol, arginfo::ArgInfo, typeinfo::TypeDesc{T}) where {T <: Type{GBoxed}}
    owns = get_ownership_transfer(arginfo) != GITransfer.NOTHING
    if may_be_null(arginfo)
        :(($name == C_NULL ? nothing : convert($(typeinfo.jtype), $name, $owns)))
    #elseif is_pointer(invoke(get_type, Tuple{ArgInfo}, arginfo))
    #    :(convert($(typeinfo.jtype), $name, $owns))
    else
        :(convert($(typeinfo.jtype), $name, $owns))
    end
end

function extract_type(typeinfo::TypeInfo, info::ObjectLike)
    if is_pointer(typeinfo)
        if typename(info)===:GParam  # these are not really GObjects
            return TypeDesc(info,:GParamSpec,:(Ptr{GParamSpec}))
        end
        TypeDesc(info,typename(info),typename(info),:(Ptr{GObject}))
    else
        # a GList has implicitly pointers to all elements
        TypeDesc(info,:INVALID,:INVALID,:GObject)
    end
end

#this should only be used for stuff that's hard to implement as cconvert
function convert_to_c(name::Symbol, info::GIArgInfo, ti::TypeDesc)
    nothing
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
jparams(args::Array{Arg}) = [a.typ != :Any ? :($(a.name)::$(a.typ)) : a.name for a in args]

# Map library names onto exports of *_jll
# TODO: make this more elegant
function symbol_from_lib(libname)
    if occursin("libglib",libname)
        return :libglib
    elseif occursin("libgobject",libname)
        return :libgobject
    elseif occursin("libgio",libname)
        return :libgio
    elseif occursin("libcairo-gobject",libname)
        return :libcairo_gobject
    elseif occursin("libpangocairo",libname)
        return :libpangocairo
    elseif occursin("libpangoft",libname)
        return :libpangoft
    elseif occursin("libpango",libname)
        return :libpango
    elseif occursin("libatk",libname)
        return :libatk
    elseif occursin("libgdk_pixbuf",libname)
        return :libgdkpixbuf
    elseif occursin("libgdk-3",libname)
        return :libgdk3
    elseif occursin("libgtk-3",libname)
        return :libgtk3
    end
    libname
end

#there's probably a better way
function make_ccall(libs, id, rtype, args)
    argtypes = Expr(:tuple, types(args)...)
    # look up symbol in our possible libraries
    lib=libs[findfirst(l->(nothing!=dlsym(dlopen(l),id)),libs)]
    slib=symbol_from_lib(lib)
    c_call = :(ccall(($id, $slib), $rtype, $argtypes))
    append!(c_call.args, names(args))
    c_call
end

# with some partial-evaluation half-magic
# (or maybe just jit-compile-time macros)
# this could be simplified significantly
function create_method(info::GIFunctionInfo)
    name = get_name(info)
    flags = get_flags(info)
    args = get_args(info)
    prologue = Any[]
    epilogue = Any[]
    retvals = Symbol[]
    cargs = Arg[]
    jargs = Arg[]
    if flags & GIFunction.IS_METHOD != 0
        object = get_container(info)
        typeinfo = extract_type(InstanceType,object)
        push!(jargs, Arg(:instance, typeinfo.jtype))
        push!(cargs, Arg(:instance, typeinfo.ctype))
    end
    if flags & GIFunction.IS_CONSTRUCTOR != 0
        #FIXME: do this with other constructors too (need to check that arg lists are different)
        if name===:new
            name = Symbol("$(get_name(get_container(info)))")
        else
            name = Symbol("$(get_name(get_container(info)))_$name")
        end
    end
    rettypeinfo=get_return_type(info)
    rettype = extract_type(rettypeinfo)
    if rettype.ctype != :Nothing && !skip_return(info)
        expr = convert_from_c(:ret,info,rettype)
        if expr != nothing
            push!(epilogue, :(ret2 = $expr))
            push!(retvals,:ret2)
        else
            push!(retvals,:ret)
        end
    end
    for arg in get_args(info)
        if is_skip(arg)
            continue
        end
        aname = Symbol("_$(get_name(arg))")
        typ = extract_type(arg)
        dir = get_direction(arg)
        if dir != GIDirection.OUT
            push!(jargs, Arg( aname, typ.jtype))
            expr = convert_to_c(aname,arg,typ)
            if expr != nothing
                push!(prologue, :($aname = $expr))
            elseif may_be_null(arg)
                push!(prologue, :($aname = (($aname == nothing) ? C_NULL : $aname)))
            end
        end

        if dir == GIDirection.IN
            push!(cargs, Arg(aname, typ.ctype))
        else
            ctype = typ.ctype
            wname = Symbol("m_$(get_name(arg))")
            atyp = get_type(arg)
            push!(prologue, :( $wname = Ref{$ctype}() ))
            if dir == GIDirection.INOUT
                push!(prologue, :( $wname[] = Base.cconvert($ctype,$aname) ))
            end
            push!(cargs, Arg(wname, :(Ptr{$ctype})))
            push!(epilogue,:( $aname = $wname[] ))
            expr = convert_from_c(aname,arg,typ)
            if expr != nothing
                push!(epilogue, :($aname = $expr))
            end
            push!(retvals, aname)
        end
    end

    # go through args again, remove length jargs for array inputs, add call
    # to length() to prologue
    args=get_args(info)
    for arg in args
        if is_skip(arg)
            continue
        end
        typ = extract_type(arg)
        dir = get_direction(arg)
        aname = Symbol("_$(get_name(arg))")
        typeinfo=get_type(arg)
        arrlen=get_array_length(typeinfo)
        if typ.gitype == GICArray && arrlen >= 0
            len_name=Symbol("_",get_name(args[arrlen+1]))
            len_i=findfirst(a->(a.name === len_name),jargs)
            if len_i !== nothing
                deleteat!(jargs,len_i)
                push!(prologue, :($len_name = length($aname)))
            end
            len_i=findfirst(a->(a===len_name),retvals)
            if len_i !==nothing
                deleteat!(retvals,len_i)
            end
        end
    end
    if rettype.gitype == GICArray
        arrlen=get_array_length(rettypeinfo)
        if arrlen >=0
            len_name=Symbol("_",get_name(args[arrlen+1]))
            len_i=findfirst(a->(a===len_name),retvals)
            if len_i !==nothing
                deleteat!(retvals,len_i)
            end
        end
    end

    if flags & GIFunction.THROWS != 0
        push!(prologue, :( err = err_buf() ))
        push!(cargs, Arg(:err, :(Ptr{Ptr{GError}})))
        pushfirst!(epilogue, :( check_err(err) ))
    end

    symb = get_symbol(info)
    j_call = Expr(:call, name, jparams(jargs)... )
    libs=get_shlibs(GINamespace(get_namespace(info)))
    c_call = :( ret = $(make_ccall(libs, string(symb), rettype.ctype, cargs)))
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
