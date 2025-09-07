# Julia wrapper for libgirepository

# https://gi.readthedocs.io/en/latest/
# https://gnome.pages.gitlab.gnome.org/gobject-introspection/girepository/

abstract type GITypelib end
abstract type GIBaseInfo end
abstract type GIRegisteredTypeInfo <: GIBaseInfo end
abstract type GICallableInfo <: GIBaseInfo end

GIRepository() = GIRepository(ccall((:gi_repository_new, libgi), Ptr{GIRepository}, ()))

unsafe_convert(::Type{Ptr{GIRepository}},w::GIRepository) = w.handle

mutable struct GIConstantInfo <: GIBaseInfo
    handle::Ptr{GIBaseInfo}
end

mutable struct GIEnumInfo <: GIRegisteredTypeInfo
    handle::Ptr{GIBaseInfo}
end

mutable struct GIFlagsInfo <: GIRegisteredTypeInfo
    handle::Ptr{GIBaseInfo}
end

mutable struct GITypeInfo <: GIBaseInfo
    handle::Ptr{GIBaseInfo}
end

mutable struct GIValueInfo <: GIBaseInfo
    handle::Ptr{GIBaseInfo}
end

mutable struct GIStructInfo <: GIRegisteredTypeInfo
    handle::Ptr{GIBaseInfo}
end

mutable struct GIObjectInfo <: GIRegisteredTypeInfo
    handle::Ptr{GIBaseInfo}
end

mutable struct GIInterfaceInfo <: GIRegisteredTypeInfo
    handle::Ptr{GIBaseInfo}
end

mutable struct GIArgInfo <: GIBaseInfo
    handle::Ptr{GIBaseInfo}
end

mutable struct GIFieldInfo <: GIBaseInfo
    handle::Ptr{GIBaseInfo}
end

mutable struct GICallbackInfo <: GICallableInfo
    handle::Ptr{GIBaseInfo}
end

mutable struct GISignalInfo <: GICallableInfo
    handle::Ptr{GIBaseInfo}
end

mutable struct GIFunctionInfo <: GICallableInfo
    handle::Ptr{GIBaseInfo}
end

# a GIBaseInfo we own a reference to
mutable struct GIInfo{Typeid}
    handle::Ptr{GIBaseInfo}
end

G_TYPE_FROM_CLASS(w::Ptr) = unsafe_load(convert(Ptr{GType}, w))
G_TYPE_FROM_INSTANCE(w::Ptr) = G_TYPE_FROM_CLASS(unsafe_load(convert(Ptr{Ptr{GType}},w)))

function GIInfo(h::Ptr{GIBaseInfo},owns=true)
    h == C_NULL && error("Cannot construct GIInfo from NULL")
    typeid = G_TYPE_FROM_CLASS(h)
    info = GIInfo{typeid}(h)
    owns && finalizer(info_unref, info)
    info
end

# don't call directly, called by gc
function info_unref(info::GIInfo)
    ccall((:gi_base_info_unref, libgi), Nothing, (Ptr{GIBaseInfo},), info.handle)
    info.handle = C_NULL
end

unsafe_convert(::Type{Ptr{GIBaseInfo}},w::GIBaseInfo) = w.handle

const GIInfoTypesShortNames = (:Invalid, :Function, :Callback, :Struct, :Boxed, :Enum,
                               :Flags, :Object, :Interface, :Constant, :Unknown, :Union,
                               :Value, :Signal, :VFunc, :Property, :Field, :Arg, :Type, :Unresolved)

const EnumGI = Int

const GIInfoTypeNames = [ Base.Symbol("GI$(name)Info") for name in GIInfoTypesShortNames]

const GIInfoTypes = Dict{Symbol, Type}()

for (i,itype) in enumerate(GIInfoTypesShortNames)
    #gt = GLib.g_type_from_name(Symbol("GI",itype,"Info"))
    #println("itype is $itype, gt is $gt")
    #let lowername = Symbol(lowercase(string(itype)))
    #    @eval const $(GIInfoTypeNames[i]) = GIInfo{$gt}
    #    GIInfoTypes[lowername] = GIInfo{gt}
    #end
end

#const GICallableInfo = Union{GIFunctionInfo,GIVFuncInfo, GICallbackInfo, GISignalInfo}
const GIEnumOrFlags = Union{GIEnumInfo,GIFlagsInfo}
#const GIRegisteredTypeInfo = Union{GIEnumOrFlags,GIInterfaceInfo, GIObjectInfo, GIStructInfo, GIUnionInfo}

#show(io::IO, ::Type{GIInfo{Typeid}}) where Typeid = print(io, GIInfoTypeNames[Typeid+1])

function show(io::IO, info::GIBaseInfo)
    show(io, typeof(info))
    print(io,"(:$(get_namespace(info)), :$(get_name(info)))")
end

#show(io::IO, info::GIArgInfo) = print(io,"GIArgInfo(:$(get_name(info)),$(extract_type(info)))")

#function show(io::IO, info::GIFunctionInfo)
#    print(io, "$(get_namespace(info)).")
#    flags = get_flags(info)
#    if flags & (GIFunction.IS_CONSTRUCTOR | GIFunction.IS_METHOD) != 0
#        cls = get_container(info)
#        print(io, "$(get_name(cls)).")
#    end
#    print(io,"$(get_name(info))(")
#    for arg in get_args(info)
#        print(io, "$(get_name(arg))::")
#        show(io, get_type(arg))
#        dir = get_direction(arg)
#        alloc = is_caller_allocates(arg)
#        if dir == GIDirection.OUT
#            print(io, " OUT($alloc)")
#        elseif dir == GIDirection.INOUT
#            print(io, " INOUT")
#        end
#        print(io, ", ")
#    end
#    print(io,")::")
#    show(io, get_return_type(info))
#    if flags & GIFunction.THROWS != 0
#        print(io, " THROWS")
#    end

#end

#function show(io::IO, info::GICallbackInfo)
#    print(io, "$(get_namespace(info)).")
#    print(io,"$(get_name(info))(")
#    for arg in get_args(info)
#        print(io, "$(get_name(arg))::")
#        show(io, get_type(arg))
#        dir = get_direction(arg)
#        alloc = is_caller_allocates(arg)
#        if dir == GIDirection.OUT
#            print(io, " OUT($alloc)")
#        elseif dir == GIDirection.INOUT
#            print(io, " INOUT")
#        end
#        print(io, ", ")
#    end
#    print(io,")::")
#    show(io, get_return_type(info))
#end

"""Represents a C library namespace, like "gtk" or "pango"."""
struct GINamespace
    name::Symbol
    function GINamespace(namespace::Symbol, version = nothing)
        #TODO: stricter version sematics?
        gi_require(namespace, version)
        new(namespace)
    end
end
convert(::Type{Cstring}, ns::GINamespace) = ns.name

function gi_require(namespace::Symbol, version = nothing)
    if isnothing(version)
        version = C_NULL
    end
    GError() do error_check
        typelib = ccall((:gi_repository_require, libgi), Ptr{GITypelib},
            (Ptr{GIRepository}, Cstring, Cstring, Cint, Ptr{Ptr{GError}}),
            repo, namespace, version, 0, error_check)
        return  typelib !== C_NULL
    end
end

function convert(::Type{GIInfo}, h::Ptr)
    gt = G_TYPE_FROM_INSTANCE(h)
    if gt == ccall((:gi_constant_info_get_type, libgi), GType, ())
        return GIConstantInfo(h)
    elseif gt == ccall((:gi_enum_info_get_type, libgi), GType, ())
        return GIEnumInfo(h)
    elseif gt == ccall((:gi_flags_info_get_type, libgi), GType, ())
        return GIFlagsInfo(h)
    elseif gt == ccall((:gi_value_info_get_type, libgi), GType, ())
        return GIValueInfo(h)
    elseif gt == ccall((:gi_type_info_get_type, libgi), GType, ())
        return GITypeInfo(h)
    elseif gt == ccall((:gi_struct_info_get_type, libgi), GType, ())
        return GIStructInfo(h)
    elseif gt == ccall((:gi_object_info_get_type, libgi), GType, ())
        return GIObjectInfo(h)
    elseif gt == ccall((:gi_interface_info_get_type, libgi), GType, ())
        return GIInterfaceInfo(h)
    elseif gt == ccall((:gi_field_info_get_type, libgi), GType, ())
        return GIFieldInfo(h)
    elseif gt == ccall((:gi_function_info_get_type, libgi), GType, ())
        return GIFunctionInfo(h)
    elseif gt == ccall((:gi_signal_info_get_type, libgi), GType, ())
        return GISignalInfo(h)
    elseif gt == ccall((:gi_callback_info_get_type, libgi), GType, ())
        return GICallbackInfo(h)
    elseif gt == ccall((:gi_arg_info_get_type, libgi), GType, ())
        return GIArgInfo(h)
    end
    return nothing
end

function gi_find_by_name(namespace::GINamespace, name::Symbol)
    info = ccall((:gi_repository_find_by_name, libgi), Ptr{GIBaseInfo},
                  (Ptr{GIRepository}, Cstring, Cstring), repo, namespace.name, name)

    info == C_NULL && error("Name $name not found in $namespace")
    convert(GIInfo,info)
end

Base.length(ns::GINamespace) = Int(ccall((:gi_repository_get_n_infos, libgi), Cint,
                               (Ptr{GIRepository}, Cstring), repo, ns))
Base.iterate(ns::GINamespace, state=1) = state > length(ns) ? nothing : (convert(GIInfo,ccall((:gi_repository_get_info, libgi), Ptr{GIBaseInfo},
                                             (Ptr{GIRepository}, Cstring, Cint), repo, ns, state-1 )), state+1)
Base.eltype(::Type{GINamespace}) = GIInfo

getindex(ns::GINamespace, name::Symbol) = gi_find_by_name(ns, name)

"""
    prepend_search_path(s::AbstractString)

Add a directory that contains *.typelib files to libgirepository's search
path.
"""
function prepend_search_path(s::AbstractString)
    ccall((:gi_repository_prepend_search_path, libgi), Cvoid, (Ptr{GIRepository}, Cstring), repo, s)
end

"""
    prepend_search_path(s::Module)

For a JLL module that includes GObject introspection data, add the directory
that contains *.typelib files to libgirepository's search path.
"""
function prepend_search_path(mod::Module)
    d = mod.find_artifact_dir()*"/lib/girepository-1.0"
    d === Missing && error("Artifact directory not found")
    prepend_search_path(d)
end

function get_all(ns::GINamespace, t::Type{T},exclude_deprecated=true) where {T<:GIBaseInfo}
    [info for info=ns if isa(info,t) && (exclude_deprecated ? !is_deprecated(info) : true)]
end

"""
    get_c_prefix(ns)

Get the C prefix for a namespace, which, for example, is "G" for GLib and "Gtk"
for GTK.
"""
function get_c_prefix(ns)
    ret = ccall((:gi_repository_get_c_prefix, libgi), Ptr{UInt8}, (Ptr{GIRepository}, Cstring), repo, ns)
    if ret != C_NULL
        bytestring(ret)
    else
        ""
    end
end

function get_version(ns::GINamespace)
    ret = ccall((:gi_repository_get_version, libgi), Ptr{UInt8}, (Ptr{GIRepository}, Cstring), repo, ns)
    if ret != C_NULL
        bytestring(ret)
    else
        ""
    end
end

function ns_id(ns::GINamespace)
    v=get_version(ns)
    "$(ns.name)-$(v)"
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
    ret = ccall((:gi_repository_get_dependencies, libgi), Ptr{Ptr{UInt8}}, (Ptr{GIRepository}, Cstring), repo, ns)
    bytestring_array(ret)
end

function get_immediate_dependencies(ns)
    ret = ccall((:gi_repository_get_immediate_dependencies, libgi), Ptr{Ptr{UInt8}}, (Ptr{GIRepository}, Cstring), repo, ns)
    bytestring_array(ret)
end

function get_shlibs(ns)
    n_elements = Ref{Csize_t}()
    names = ccall((:gi_repository_get_shared_libraries, libgi), Ptr{Cstring}, (Ptr{GIRepository}, Cstring, Ref{Csize_t}), repo, ns, n_elements)
    if names != C_NULL
        collect(bytestring.(unsafe_wrap(Vector{Cstring}, names, n_elements[])))
    else
        String[]
    end
end
get_shlibs(info::GIBaseInfo) = get_shlibs(get_namespace(info))

function find_by_gtype(gtypeid::Csize_t)
    GIInfo(ccall((:gi_repository_find_by_gtype, libgi), Ptr{GIBaseInfo}, (Ptr{GIRepository}, Csize_t), repo, gtypeid))
end

#GIInfoTypes[:method] = GIFunctionInfo
GIInfoTypes[:callable] = GICallableInfo
GIInfoTypes[:registered_type] = GIRegisteredTypeInfo
GIInfoTypes[:object] = GIObjectInfo
GIInfoTypes[:interface] = GIInterfaceInfo
GIInfoTypes[:base] = GIBaseInfo
GIInfoTypes[:constant] = GIConstantInfo
GIInfoTypes[:enum] = GIEnumInfo
GIInfoTypes[:flags] = GIFlagsInfo
GIInfoTypes[:type] = GITypeInfo
GIInfoTypes[:value] = GIValueInfo
GIInfoTypes[:struct] = GIStructInfo
GIInfoTypes[:field] = GIFieldInfo
GIInfoTypes[:signal] = GISignalInfo
GIInfoTypes[:function] = GIFunctionInfo
GIInfoTypes[:callback] = GICallbackInfo
GIInfoTypes[:arg] = GIArgInfo

Maybe(T) = Union{T,Nothing}
const MaybeGIInfo = Maybe(GIInfo)

# used on outputs of libgirepository functions
rconvert(t,v) = rconvert(t,v,false)
rconvert(t::Type,val,owns) = convert(t,val)
rconvert(::Type{String}, val,owns) = bytestring(val) #,owns)
function rconvert(::Type{Symbol}, val,owns)
    if val != C_NULL
        Symbol(bytestring(val))#,owns) )
    else
        return :nothing
    end
end
rconvert(::Type{GIInfo}, val::Ptr{GIBaseInfo},owns) = convert(GIInfo,val)

for typ in [GIInfo, String, GObject]
    @eval rconvert(::Type{Union{$typ,Nothing}}, val,owns) = (val == C_NULL) ? nothing : rconvert($typ,val,owns)
end
rconvert(::Type{Nothing}, val) = error("something went wrong")

# one-> many relationships
for (owner, property) in [
    (:object, :method), (:object, :signal), (:object, :interface),
    (:object, :constant), (:object, :field),
    (:interface, :method), (:interface, :signal),
    (:callable, :arg), (:enum, :value), 
    (:struct, :field), (:struct, :method),
    (:interface, :prerequisite)
    ]
    @eval function $(Symbol("get_$(property)s"))(info::$(GIInfoTypes[owner]))
        n = Int(ccall(($("gi_$(owner)_info_get_n_$(property)s"), libgi), Cint, (Ptr{GIBaseInfo},), info))
        GIBaseInfo[ convert(GIInfo, ccall(($("gi_$(owner)_info_get_$property"), libgi), Ptr{GIBaseInfo},
                      (Ptr{GIBaseInfo}, Cint), info, i)) for i=0:n-1]
    end
    if property === :method
        @eval function $(Symbol("find_$(property)"))(info::$(GIInfoTypes[owner]), name)
            ptr = ccall(($("gi_$(owner)_info_find_$(property)"), libgi), Ptr{GIBaseInfo},
                            (Ptr{GIBaseInfo}, Ptr{UInt8}), info, name)
            rconvert(MaybeGIInfo, ptr, true)
        end
    end
end

function get_properties(info::GIObjectInfo)
    n = Int(ccall(("gi_object_info_get_n_properties", libgi), Cint, (Ptr{GIBaseInfo},), info))
    GIInfo[ GIInfo( ccall(("gi_object_info_get_property", libgi), Ptr{GIBaseInfo},
                  (Ptr{GIBaseInfo}, Cint), info, i)) for i=0:n-1]
end

function get_properties(info::GIInterfaceInfo)
    n = Int(ccall(("gi_interface_info_get_n_properties", libgi), Cint, (Ptr{GIBaseInfo},), info))
    GIInfo[ GIInfo( ccall(("gi_interface_info_get_property", libgi), Ptr{GIBaseInfo},
                  (Ptr{GIBaseInfo}, Cint), info, i)) for i=0:n-1]
end

# including the interfaces
function get_all_signals(info::GIObjectInfo)
    sigs = get_signals(info)
    for interf in get_interfaces(info)
        append!(sigs, get_signals(interf))
    end
    sigs
end

#getindex(info::GIRegisteredTypeInfo, name::Symbol) = find_method(info, name)

# one->one
# FIXME: memory management of GIInfo:s
ctypes = Dict(GIInfo=>Ptr{GIBaseInfo},
         MaybeGIInfo=>Ptr{GIBaseInfo},
          Symbol=>Ptr{UInt8})
for (owner,property,typ) in [
    (:base, :name, Symbol), (:base, :namespace, Symbol), #(:base, :type, Int),
    (:base, :container, MaybeGIInfo),
    (:registered_type, :g_type, GType), (:registered_type, :type_name, Symbol), (:object, :parent, MaybeGIInfo), (:object, :type_init_function_name, Symbol),
    (:callable, :return_type, GIInfo), (:callable, :caller_owns, EnumGI), (:callable, :instance_ownership_transfer, EnumGI), (:registered_type, :type_init_function_name, Symbol),
    (:function, :flags, EnumGI), (:function, :symbol, Symbol), #(:property, :type, GIInfo), (:property, :ownership_transfer, EnumGI), (:property, :flags, EnumGI),
    (:arg, :type_info, GIInfo), (:arg, :direction, EnumGI), (:arg, :ownership_transfer, EnumGI), #(:function, :property, MaybeGIInfo),
    (:arg, :destroy, Cint), (:arg, :scope, EnumGI),
    (:type, :tag, EnumGI), (:type, :interface, MaybeGIInfo), (:type, :array_type, EnumGI),
    (:type, :array_fixed_size, Cint),
    (:constant, :type_info, GITypeInfo),
    (:value, :value, Int64), (:field, :type_info, GITypeInfo), 
    (:enum, :storage_type, EnumGI)
    ]

    ctype = get(ctypes, typ, typ)
    @eval function $(Symbol("get_$(property)"))(info::$(GIInfoTypes[owner]))
        rconvert($typ,ccall(($("gi_$(owner)_info_get_$(property)"), libgi), $ctype, (Ptr{GIBaseInfo},), info))
    end
end

function get_closure_index(info::GIArgInfo)
    out_closure_index = Ref{Cuint}()
    retval = ccall(("gi_arg_info_get_closure_index", libgi), Cint, (Ptr{GIBaseInfo},Ref{Cuint}), info, out_closure_index)
    if retval != 0
        return out_closure_index[]
    else
        return nothing
    end
end

function get_array_length_index(info::GITypeInfo)
    out_array_length_index = Ref{Cuint}()
    retval = ccall(("gi_type_info_get_array_length_index", libgi), Cint, (Ptr{GIBaseInfo},Ref{Cuint}), info, out_array_length_index)
    if retval != 0
        return out_array_length_index[]
    else
        return nothing
    end
end


function get_storage_type(info::GIFlagsInfo)
    rconvert(Int,ccall(("gi_enum_info_get_storage_type", libgi), Int, (Ptr{GIBaseInfo},), info))
end

function get_attribute(info,name)
    ret=ccall(("gi_base_info_get_attribute",libgi),Ptr{UInt8},(Ptr{GIBaseInfo},Ptr{UInt8}),info,name)
    ret==C_NULL ? nothing : bytestring(ret)
end

#get_name(info::GITypeInfo) = Symbol("<gtype>")
#get_name(info::GIInvalidInfo) = Symbol("<INVALID>")

get_param_type(info::GITypeInfo,n) = rconvert(MaybeGIInfo, ccall(("gi_type_info_get_param_type", libgi), Ptr{GIBaseInfo}, (Ptr{GIBaseInfo}, Cint), info, n))

#pretend that CallableInfo is a ArgInfo describing the return value
const ArgInfo = Union{GIArgInfo,GICallableInfo}
get_ownership_transfer(ai::GICallableInfo) = get_caller_owns(ai)
may_be_null(ai::GICallableInfo) = may_return_null(ai)
get_type_info(ci::GICallableInfo) = get_return_type(ci)

for (owner,flag) in [
    (:type, :is_pointer), (:callable, :may_return_null), (:callable, :skip_return),
    (:callable, :is_method), (:callable, :can_throw_gerror),
    (:arg, :is_caller_allocates), (:arg, :may_be_null),
    (:arg, :is_skip), (:arg, :is_return_value), (:arg, :is_optional),
    (:type, :is_zero_terminated),
    (:base, :is_deprecated),
    (:struct, :is_gtype_struct),
    (:object, :get_abstract)
    ]

    @eval function $flag(info::$(GIInfoTypes[owner]))
        ret = ccall(($("gi_$(owner)_info_$(flag)"), libgi), Cint, (Ptr{GIBaseInfo},), info)
        return ret != 0
    end
end

is_gobject(::Nothing) = false
function is_gobject(info::GIObjectInfo)
    if get_g_type(info) == GLib.g_type(GLib.GObject)
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
        if p isa GIObjectInfo
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
get_base_type(info::GIConstantInfo) = get_base_type(get_type_info(info))
function get_base_type(info::GITypeInfo)
    tag = get_tag(info)
    if tag <= TAG_BASIC_MAX
        return typetag_primitive[tag+1]
    elseif tag == TAG_INTERFACE
        # Object Types n such -- we have to figure out what the type is
        interf_info = get_interface(info) # output here is a BaseInfo
        isnothing(interf_info) && return Nothing
        # docs say "inspect the type of the returned BaseInfo to further query whether it is a concrete GObject, a GInterface, a structure, etc."
        if interf_info isa GIStructInfo
            gtyp=get_g_type(interf_info)
            boxed_gtype = GLib.g_type_from_name(:GBoxed)
            if GLib.g_isa(gtyp,boxed_gtype)
                return GBoxed
            else
                return interf_info
            end
        elseif interf_info isa GIEnumInfo
            return CEnum.Cenum
        elseif interf_info isa GIFlagsInfo
            return BitFlags.BitFlag
        elseif interf_info isa GICallbackInfo
            return Function
        elseif interf_info isa GIObjectInfo
            if is_gobject(interf_info)
                return GObject
            else
                return get_toplevel(interf_info)
            end
        elseif interf_info isa GIInterfaceInfo
            return GInterface
        else
            name=get_name(interf_info)
            println("$name, Unhandled type: ", typ," ",get_type(interf_info))
            throw(NotImplementedError())
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
        #throw(NotImplementedError())
        return Nothing
    end
end

function isopaque(info::GIStructInfo)
    fields=get_fields(info)
    return length(fields)==0
end

#get_call(info::GITypeInfo) = get_call(get_container(info))
#get_call(info::GIArgInfo) = get_container(info)
#get_call(info::GICallableInfo) = info

#function show(io::IO,info::GITypeInfo)
#    bt = get_base_type(info)
#    print(io,"GITypeInfo: ")
#    if is_pointer(info)
#        print(io,"Ptr{")
#    end
#    if isa(bt,Type) && bt <: GIArrayType && bt != Nothing
#        zero = is_zero_terminated(info) ? "zt" : ""
#        print(io,"$bt($zero,")
#        fs = get_array_fixed_size(info)
#        len = get_array_length(info)
#        if fs >= 0
#            show(io, fs)
#        elseif len >= 0
#            call = get_call(info)
#            arg = get_args(call)[len+1]
#            show(io, get_name(arg))
#        end
#        print(io,", ")
#        param = get_param_type(info,0)
#        show(io,param)
#        print(io,")")
#    elseif isa(bt,Type) && bt <: GLib._LList && bt != Nothing
#        print(io,"$bt{")
#        param = get_param_type(info,0)
#        show(io,param)
#        print(io,"}")
#    else
#        print(io,"$bt")
#    end
#    if is_pointer(info)
#        print(io,"}")
#    end
#end

function get_constant_value(::Type{T}, info) where T
    x=Ref{T}(0)
    siz = ccall((:gi_constant_info_get_value,libgi),Cint,(Ptr{GIBaseInfo}, Ref{T}), info, x)
    x[]
end

function get_value(info::GIConstantInfo)
    typ = get_base_type(info)
    prim = coalesce(typ in typetag_primitive[2:12],false)
    if prim
        get_constant_value(typ,info)
    elseif typ <: Number # backup
        get_constant_value(Int64,info)
    elseif typ == String
        x = Array{Cstring,1}(undef,1)
        size = ccall((:gi_constant_info_get_value,libgi),Cint,(Ptr{GIBaseInfo}, Ptr{Cstring}), info, x)

        val = unsafe_string(x[1])

        ccall((:gi_constant_info_free_value,libgi), Nothing, (Ptr{GIBaseInfo}, Ptr{Nothing}), info, x)
        val
    else
        throw(NotImplementedError("Constant with type $typ not supported"))
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
        if val !== nothing
            push!(consts, (name,val))
        end
    end
    consts
end

function get_enum_values(info::GIEnumOrFlags)
    [(get_name(i),get_value(i)) for i in get_values(GIEnumInfo(info.handle))]
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
    const IS_ASYNC       = 32
end

baremodule GIDirection
    const IN    = 0
    const OUT   = 1
    const INOUT = 2
end

baremodule GITransfer
    const NOTHING    = 0
    const CONTAINER  = 1
    const EVERYTHING = 2
end

baremodule GIScopeType
    const INVALID  = 0
    const CALL     = 1
    const ASYNC    = 2
    const NOTIFIED = 3
    const FOREVER  = 4
end
