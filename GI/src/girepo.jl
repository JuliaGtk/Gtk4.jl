# Julia wrapper for libgirepository

abstract type GIRepository end

abstract type GITypelib end

abstract type GIBaseInfo end
# a GIBaseInfo we own a reference to
mutable struct GIInfo{Typeid}
    handle::Ptr{GIBaseInfo}
end

function GIInfo(h::Ptr{GIBaseInfo},owns=true)
    if h == C_NULL
        error("Cannot construct GIInfo from NULL")
    end
    typeid = ccall((:g_base_info_get_type, libgi), Int, (Ptr{GIBaseInfo},), h)
    info = GIInfo{typeid}(h)
    owns && finalizer(info_unref, info)
    info
end

# don't call directly, called by gc
function info_unref(info::GIInfo)
    #core dumps on reload("GTK.jl"),
    ccall((:g_base_info_unref, libgi), Nothing, (Ptr{GIBaseInfo},), info.handle)
    info.handle = C_NULL
end

convert(::Type{Ptr{GIBaseInfo}},w::GIInfo) = w.handle
unsafe_convert(::Type{Ptr{GIBaseInfo}},w::GIInfo) = w.handle
#convert(::Type{GIBaseInfo},w::GIInfo) = w.handle

const GIInfoTypesShortNames = (:Invalid, :Function, :Callback, :Struct, :Boxed, :Enum,
                               :Flags, :Object, :Interface, :Constant, :Unknown, :Union,
                               :Value, :Signal, :VFunc, :Property, :Field, :Arg, :Type, :Unresolved)

const EnumGI = Int

const GIInfoTypeNames = [ Base.Symbol("GI$(name)Info") for name in GIInfoTypesShortNames]

const GIInfoTypes = Dict{Symbol, Type}()

for (i,itype) in enumerate(GIInfoTypesShortNames)
    let lowername = Symbol(lowercase(string(itype)))
        @eval const $(GIInfoTypeNames[i]) = GIInfo{$(i-1)}
        GIInfoTypes[lowername] = GIInfo{i-1}
    end
end

const GICallableInfo = Union{GIFunctionInfo,GIVFuncInfo, GICallbackInfo, GISignalInfo}
const GIEnumOrFlags = Union{GIEnumInfo,GIFlagsInfo}
const GIRegisteredTypeInfo = Union{GIEnumOrFlags,GIInterfaceInfo, GIObjectInfo, GIStructInfo, GIUnionInfo}

show(io::IO, ::Type{GIInfo{Typeid}}) where Typeid = print(io, GIInfoTypeNames[Typeid+1])

function show(io::IO, info::GIInfo)
    show(io, typeof(info))
    print(io,"(:$(get_namespace(info)), :$(get_name(info)))")
end

#show(io::IO, info::GITypeInfo) = print(io,"GITypeInfo($(extract_type(info)))")
show(io::IO, info::GIArgInfo) = print(io,"GIArgInfo(:$(get_name(info)),$(extract_type(info)))")
#showcompact(io::IO, info::GIArgInfo) = show(io,info) # bug in show.jl ?

function show(io::IO, info::GIFunctionInfo)
    print(io, "$(get_namespace(info)).")
    flags = get_flags(info)
    if flags & (GIFunction.IS_CONSTRUCTOR | GIFunction.IS_METHOD) != 0
        cls = get_container(info)
        print(io, "$(get_name(cls)).")
    end
    print(io,"$(get_name(info))(")
    for arg in get_args(info)
        print(io, "$(get_name(arg))::")
        show(io, get_type(arg))
        dir = get_direction(arg)
        alloc = is_caller_allocates(arg)
        if dir == GIDirection.OUT
            print(io, " OUT($alloc)")
        elseif dir == GIDirection.INOUT
            print(io, " INOUT")
        end
        print(io, ", ")
    end
    print(io,")::")
    show(io, get_return_type(info))
    if flags & GIFunction.THROWS != 0
        print(io, " THROWS")
    end

end

function show(io::IO, info::GICallbackInfo)
    print(io, "$(get_namespace(info)).")
    print(io,"$(get_name(info))(")
    for arg in get_args(info)
        print(io, "$(get_name(arg))::")
        show(io, get_type(arg))
        dir = get_direction(arg)
        alloc = is_caller_allocates(arg)
        if dir == GIDirection.OUT
            print(io, " OUT($alloc)")
        elseif dir == GIDirection.INOUT
            print(io, " INOUT")
        end
        print(io, ", ")
    end
    print(io,")::")
    show(io, get_return_type(info))
end


struct GINamespace
    name::Symbol
    function GINamespace(namespace::Symbol, version=nothing)
        #TODO: stricter version sematics?
        gi_require(namespace, version)
        new(namespace)
    end
end
convert(::Type{Symbol}, ns::GINamespace) = ns.name
convert(::Type{Cstring}, ns::GINamespace) = ns.name
convert(::Type{Ptr{UInt8}}, ns::GINamespace) = convert(Ptr{UInt8}, ns.name)
unsafe_convert(::Type{Symbol}, ns::GINamespace) = ns.name
unsafe_convert(::Type{Ptr{UInt8}}, ns::GINamespace) = convert(Ptr{UInt8}, ns.name)

Base.:(==)(a::GINamespace, b::GINamespace) = (a.name === b.name)

function gi_require(namespace::Symbol, version=nothing)
    if version==nothing
        version = C_NULL
    end
    GError() do error_check
        typelib = ccall((:g_irepository_require, libgi), Ptr{GITypelib},
            (Ptr{GIRepository}, Ptr{UInt8}, Ptr{UInt8}, Cint, Ptr{Ptr{GError}}),
            C_NULL, namespace, version, 0, error_check)
        return  typelib !== C_NULL
    end
end

function gi_find_by_name(namespace::GINamespace, name::Symbol)
    info = ccall((:g_irepository_find_by_name, libgi), Ptr{GIBaseInfo},
                  (Ptr{GIRepository}, Cstring, Cstring), C_NULL, namespace.name, name)

    if info == C_NULL
        error("Name $name not found in $namespace")
    end
    GIInfo(info)
end

#GIInfo(namespace, name::Symbol) = gi_find_by_name(namespace, name)

Base.length(ns::GINamespace) = Int(ccall((:g_irepository_get_n_infos, libgi), Cint,
                               (Ptr{GIRepository}, Cstring), C_NULL, ns))
Base.iterate(ns::GINamespace, state=1) = state > length(ns) ? nothing : (GIInfo(ccall((:g_irepository_get_info, libgi), Ptr{GIBaseInfo},
                                             (Ptr{GIRepository}, Cstring, Cint), C_NULL, ns, state-1 )), state+1)
Base.eltype(::Type{GINamespace}) = GIInfo

getindex(ns::GINamespace, name::Symbol) = gi_find_by_name(ns, name)

function get_all(ns::GINamespace, t::Type{T},exclude_deprecated=true) where {T<:GIInfo}
    [info for info=ns if isa(info,t) && (exclude_deprecated ? !is_deprecated(info) : true)]
end

function get_c_prefix(ns)
    ret = ccall((:g_irepository_get_c_prefix, libgi), Ptr{UInt8}, (Ptr{GIRepository}, Cstring), C_NULL, ns)
    if ret != C_NULL
        bytestring(ret)
    else
        ""
    end
end

function bytestring_array(ptr)
    ret=String[]
    i=1
    while unsafe_load(ptr,i)!=C_NULL
        push!(ret,bytestring(unsafe_load(ptr,i)))
        i+=1
    end
    ret
end

function get_dependencies(ns)
    ret = ccall((:g_irepository_get_dependencies, libgi), Ptr{Ptr{UInt8}}, (Ptr{GIRepository}, Cstring), C_NULL, ns)
    bytestring_array(ret)
end

function get_immediate_dependencies(ns)
    ret = ccall((:g_irepository_get_immediate_dependencies, libgi), Ptr{Ptr{UInt8}}, (Ptr{GIRepository}, Cstring), C_NULL, ns)
    bytestring_array(ret)
end

function get_shlibs(ns)
    names = ccall((:g_irepository_get_shared_library, libgi), Ptr{UInt8}, (Ptr{GIRepository}, Cstring), C_NULL, ns)
    if names != C_NULL
        [bytestring(s) for s in split(bytestring(names),",")]
    else
        String[]
    end
end
get_shlibs(info::GIInfo) = get_shlibs(get_namespace(info))

function find_by_gtype(gtypeid::Csize_t)
    GIInfo(ccall((:g_irepository_find_by_gtype, libgi), Ptr{GIBaseInfo}, (Ptr{GIRepository}, Csize_t), C_NULL, gtypeid))
end

GIInfoTypes[:method] = GIFunctionInfo
GIInfoTypes[:callable] = GICallableInfo
GIInfoTypes[:registered_type] = GIRegisteredTypeInfo
GIInfoTypes[:base] = GIInfo
GIInfoTypes[:enum] = GIEnumOrFlags

Maybe(T) = Union{T,Nothing}

# used on outputs of libgirepository functions
rconvert(t,v) = rconvert(t,v,false)
rconvert(t::Type,val,owns) = convert(t,val)
rconvert(::Type{String}, val,owns) = bytestring(val) #,owns)
rconvert(::Type{Symbol}, val,owns) = Symbol(bytestring(val))#,owns) )
rconvert(::Type{GIInfo}, val::Ptr{GIBaseInfo},owns) = GIInfo(val,owns)
#rconvert{T}(::Type{Union(T,Nothing)}, val,owns) = (val == C_NULL) ? nothing : rconvert(T,val,owns)
# :(
for typ in [GIInfo, String, GObject]
    @eval rconvert(::Type{Union{$typ,Nothing}}, val,owns) = (val == C_NULL) ? nothing : rconvert($typ,val,owns)
end
rconvert(::Type{Nothing}, val) = error("something went wrong")

# one-> many relationships
for (owner, property) in [
    (:object, :method), (:object, :signal), (:object, :interface),
    (:object, :constant), (:object, :field),
    (:interface, :method), (:interface, :signal), (:callable, :arg),
    (:enum, :value), (:struct, :field), (:struct, :method),
    (:interface, :prerequisite)]
    @eval function $(Symbol("get_$(property)s"))(info::$(GIInfoTypes[owner]))
        n = Int(ccall(($("g_$(owner)_info_get_n_$(property)s"), libgi), Cint, (Ptr{GIBaseInfo},), info))
        GIInfo[ GIInfo( ccall(($("g_$(owner)_info_get_$property"), libgi), Ptr{GIBaseInfo},
                      (Ptr{GIBaseInfo}, Cint), info, i)) for i=0:n-1]
    end
    if property == :method
        @eval function $(Symbol("find_$(property)"))(info::$(GIInfoTypes[owner]), name)
            ptr = ccall(($("g_$(owner)_info_find_$(property)"), libgi), Ptr{GIBaseInfo},
                            (Ptr{GIBaseInfo}, Ptr{UInt8}), info, name)
            rconvert(Maybe(GIInfo), ptr, true)
        end
    end
end

function get_properties(info::GIObjectInfo)
    n = Int(ccall(("g_object_info_get_n_properties", libgi), Cint, (Ptr{GIBaseInfo},), info))
    GIInfo[ GIInfo( ccall(("g_object_info_get_property", libgi), Ptr{GIBaseInfo},
                  (Ptr{GIBaseInfo}, Cint), info, i)) for i=0:n-1]
end

function get_properties(info::GIInterfaceInfo)
    n = Int(ccall(("g_interface_info_get_n_properties", libgi), Cint, (Ptr{GIBaseInfo},), info))
    GIInfo[ GIInfo( ccall(("g_interface_info_get_property", libgi), Ptr{GIBaseInfo},
                  (Ptr{GIBaseInfo}, Cint), info, i)) for i=0:n-1]
end

getindex(info::GIRegisteredTypeInfo, name::Symbol) = find_method(info, name)

const MaybeGIInfo = Maybe(GIInfo)
# one->one
# FIXME: memory management of GIInfo:s
ctypes = Dict(GIInfo=>Ptr{GIBaseInfo},
         MaybeGIInfo=>Ptr{GIBaseInfo},
          Symbol=>Ptr{UInt8})
for (owner,property,typ) in [
    (:base, :name, Symbol), (:base, :namespace, Symbol), (:base, :type, Int),
    (:base, :container, MaybeGIInfo), (:registered_type, :g_type, GType), (:object, :parent, MaybeGIInfo), (:object, :type_init, Symbol),
    (:callable, :return_type, GIInfo), (:callable, :caller_owns, EnumGI), (:registered_type, :type_init, Symbol),
    (:function, :flags, EnumGI), (:function, :symbol, Symbol), (:property, :type, GIInfo), (:property, :ownership_transfer, EnumGI), (:property, :flags, EnumGI),
    (:arg, :type, GIInfo), (:arg, :direction, EnumGI), (:arg, :ownership_transfer, EnumGI), #(:function, :property, MaybeGIInfo),
    (:type, :tag, EnumGI), (:type, :interface, MaybeGIInfo), (:type, :array_type, EnumGI),
    (:type, :array_length, Cint), (:type, :array_fixed_size, Cint), (:constant, :type, GIInfo),
    (:value, :value, Int64), (:field, :type, GIInfo), (:enum, :storage_type, EnumGI) ]

    ctype = get(ctypes, typ, typ)
    @eval function $(Symbol("get_$(property)"))(info::$(GIInfoTypes[owner]))
        rconvert($typ,ccall(($("g_$(owner)_info_get_$(property)"), libgi), $ctype, (Ptr{GIBaseInfo},), info))
    end
end

function get_attribute(info,name)
    ret=ccall(("g_base_info_get_attribute",libgi),Ptr{UInt8},(Ptr{GIBaseInfo},Ptr{UInt8}),info,name)
    ret==C_NULL ? nothing : bytestring(ret)
end

get_name(info::GITypeInfo) = Symbol("<gtype>")
get_name(info::GIInvalidInfo) = Symbol("<INVALID>")

get_param_type(info::GITypeInfo,n) = rconvert(MaybeGIInfo, ccall(("g_type_info_get_param_type", libgi), Ptr{GIBaseInfo}, (Ptr{GIBaseInfo}, Cint), info, n))

#pretend that CallableInfo is a ArgInfo describing the return value
const ArgInfo = Union{GIArgInfo,GICallableInfo}
get_ownership_transfer(ai::GICallableInfo) = get_caller_owns(ai)
may_be_null(ai::GICallableInfo) = may_return_null(ai)

for (owner,flag) in [
    (:type, :is_pointer), (:callable, :may_return_null), (:callable, :skip_return),
    (:arg, :is_caller_allocates), (:arg, :may_be_null),
    (:arg, :is_skip), (:arg, :is_return_value), (:arg, :is_optional),
    (:type, :is_zero_terminated), (:base, :is_deprecated), (:struct, :is_gtype_struct),
    (:object, :get_abstract)]

    @eval function $flag(info::$(GIInfoTypes[owner]))
        ret = ccall(($("g_$(owner)_info_$(flag)"), libgi), Cint, (Ptr{GIBaseInfo},), info)
        return ret != 0
    end
end

is_gobject(::Nothing) = false
function is_gobject(info::GIObjectInfo)
    if GLib.g_type_name(get_g_type(info)) == :GObject
        true
    else
        is_gobject(get_parent(info))
    end
end

# Look through the prerequisites for an interface and return the one that is a
# subclass of GObject. If there are none, return GObject.
function get_gobj_prerequisite(info::GIInterfaceInfo)
    prereqs = get_prerequisites(info)
    length(prereqs) == 0 && return :GObject
    for p in prereqs
        if GIInfoTypeNames[get_type(p)+1] === :GIObjectInfo
            return get_full_name(p)
        end
    end
    return :GObject
end

const typetag_primitive = [
    Nothing,Bool,Int8,UInt8,
    Int16,UInt16,Int32,UInt32,
    Int64,UInt64,Cfloat,Cdouble,
    GType,
    String
    ]
const TAG_BASIC_MAX = 13
const TAG_FILENAME = 14
const TAG_ARRAY = 15
const TAG_INTERFACE = 16
const TAG_GLIST = 17
const TAG_GSLIST = 18
const TAG_GHASH = 19
const TAG_GERROR = 20
const TAG_UNICHAR = 21

abstract type GIArrayType{kind} end
const GI_ARRAY_TYPE_C = 0
const GI_ARRAY_TYPE_ARRAY = 1
const GI_ARRAY_TYPE_PTR_ARRAY = 2
const GI_ARRAY_TYPE_BYTE_ARRAY =3
const GICArray = GIArrayType{GI_ARRAY_TYPE_C}

function get_full_name(info)
    ns=get_namespace(info)
    Symbol(get_c_prefix(ns),string(get_name(info)))
end

"""Get the Julia type corresponding to a GITypeInfo. Not necessarily the actual
type but a base type."""
get_base_type(info::GIConstantInfo) = get_base_type(get_type(info))
function get_base_type(info::GITypeInfo)
    tag = get_tag(info)
    if tag <= TAG_BASIC_MAX
        return typetag_primitive[tag+1]
    elseif tag == TAG_INTERFACE
        # Object Types n such -- we have to figure out what the type is
        interf_info = get_interface(info) # output here is a BaseInfo
        # docs say "inspect the type of the returned BaseInfo to further query whether it is a concrete GObject, a GInterface, a structure, etc."
        typ=GIInfoTypeNames[get_type(interf_info)+1]
        if typ===:GIStructInfo
            gtyp=get_g_type(interf_info)
            boxed_gtype = GLib.g_type_from_name(:GBoxed)
            if GLib.g_isa(gtyp,boxed_gtype)
                return GBoxed
            else
                # we don't have a type defined so return the name
                return get_full_name(interf_info)
            end
        elseif typ===:GIEnumInfo
            storage_typ = typetag_primitive[get_storage_type(interf_info)]
            return Enum{storage_typ}
        elseif typ===:GIFlagsInfo
            return Int32 # TODO: get the storage type using GI
        elseif typ===:GICallbackInfo
            return Function
        elseif typ===:GIObjectInfo
            return GObject
        elseif typ===:GIInterfaceInfo
            return GInterface
        else
            name=get_name(interf_info)
            #println("$name, Unhandled type: ", typ," ",get_type(interf_info))
            throw(NotImplementedError)
        end
    elseif tag == TAG_ARRAY
        atype=Integer(get_array_type(info))
        if atype==GI_ARRAY_TYPE_ARRAY
            return GArray
        elseif atype==GI_ARRAY_TYPE_PTR_ARRAY
            return GPtrArray
        elseif atype==GI_ARRAY_TYPE_BYTE_ARRAY
            return GByteArray
        end
        GIArrayType{atype}
    elseif tag == TAG_GLIST
        GLib._GList
    elseif tag == TAG_GSLIST
        GLib._GSList
    elseif tag == TAG_GERROR
        GError
    elseif tag == TAG_GHASH
        GHashTable
    elseif tag == TAG_FILENAME
        String #FIXME: on funky platforms this may not be utf8/ascii
    else
        #print("base type not implemented: ",tag)
        #throw(NotImplementedError)
        return Nothing
    end
end

function isopaque(info::GIStructInfo)
    fields=get_fields(info)
    return length(fields)==0
end

get_call(info::GITypeInfo) = get_call(get_container(info))
get_call(info::GIArgInfo) = get_container(info)
get_call(info::GICallableInfo) = info

function show(io::IO,info::GITypeInfo)
    bt = get_base_type(info)
    print(io,"GITypeInfo: ")
    if is_pointer(info)
        print(io,"Ptr{")
    end
    if isa(bt,Type) && bt <: GIArrayType && bt != Nothing
        zero = is_zero_terminated(info) ? "zt" : ""
        print(io,"$bt($zero,")
        fs = get_array_fixed_size(info)
        len = get_array_length(info)
        if fs >= 0
            show(io, fs)
        elseif len >= 0
            call = get_call(info)
            arg = get_args(call)[len+1]
            show(io, get_name(arg))
        end
        print(io,", ")
        param = get_param_type(info,0)
        show(io,param)
        print(io,")")
    elseif isa(bt,Type) && bt <: GLib._LList && bt != Nothing
        print(io,"$bt{")
        param = get_param_type(info,0)
        show(io,param)
        print(io,"}")
    else
        print(io,"$bt")
    end
    if is_pointer(info)
        print(io,"}")
    end
end

function get_constant_value(typ,info)
    eval(quote
        x = Ref{$typ}(0)
        size = ccall((:g_constant_info_get_value,libgi),Cint,(Ptr{GIBaseInfo}, Ref{$typ}), $info, x)
        x[]
    end)
end

function get_value(info::GIConstantInfo)
    typ = get_base_type(info)
    if typ in typetag_primitive[2:12]
        get_constant_value(typ,info)
    elseif typ <: Number # backup
        get_constant_value(Int64,info)
    elseif typ == String
        x = Array{Cstring,1}(undef,1)
        size = ccall((:g_constant_info_get_value,libgi),Cint,(Ptr{GIBaseInfo}, Ptr{Cstring}), info, x)

        val = unsafe_string(x[1])

        ccall((:g_constant_info_free_value,libgi), Nothing, (Ptr{GIBaseInfo}, Ptr{Nothing}), info, x)
        val
    else
        nothing#unimplemented
    end
end

function get_consts(gns,exclude_deprecated=true)
    consts = Tuple{Symbol,Any}[]
    for c in get_all(gns,GIConstantInfo,exclude_deprecated)
        name = get_name(c)
        if !occursin(r"^[a-zA-Z_]",string(name))
            name = Symbol("_$name") #FIXME: might collide
        end
        val = get_value(c)
        if val != nothing
            push!(consts, (name,val))
        end
    end
    consts
end

function get_enum_values(info::GIEnumOrFlags)
    [(get_name(i),get_value(i)) for i in get_values(info)]
end

function get_structs(gns,exclude_deprecated=true)
    structs = get_all(gns, GIStructInfo, exclude_deprecated)
end

baremodule GIFunction
    const IS_METHOD      = 1
    const IS_CONSTRUCTOR = 2
    const IS_GETTER      = 4
    const IS_SETTER      = 8
    const WRAPS_VFUNC    = 16
    const THROWS         = 32
end

baremodule GIDirection
    const IN = 0
    const OUT =1
    const INOUT =2
end

baremodule GITransfer
    const NOTHING =0
    const CONTAINER =1
    const EVERYTHING =2
end
