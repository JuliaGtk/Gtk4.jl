module GLib

if isdefined(Base, :Experimental) && isdefined(Base.Experimental, Symbol("@optlevel"))
    @eval Base.Experimental.@optlevel 1
end

import Base: convert, copy, run, show, size, length, getindex, setindex!, get,
             iterate, eltype, isempty, ndims, stride, strides, popfirst!,
             empty!, append!, reverse!, pushfirst!, pop!, push!, splice!, insert!, deleteat!, delete!,
             sigatomic_begin, sigatomic_end, unsafe_convert,
             getproperty, setproperty!, propertynames, getindex, setindex!, print, replace
import CEnum: @cenum, CEnum
import BitFlags: @bitflag, BitFlag

using Glib_jll
using Libdl, Preferences

export Maybe

export GList, GSList, glist_iter, _GSList, _GList, GError, GVariant, GType, GBoxed
export GObject, GInitiallyUnowned, GInterface, GTypeInterface, _GTypeInterface, GParam
export GByteArray, GHashTable, GPtrArray
export g_timeout_add, g_idle_add, @idle_add, @guarded, g_source_remove
export cfunction_
export gobject_ref, signal_connect, signal_emit, signal_handler_disconnect
export signal_handler_block, signal_handler_unblock
export add_action, add_stateful_action

export get_gtk_property, set_gtk_property!, gtk_propertynames, bind_property, unbind_property
export bytestring, nothing_to_null, setproperties!, string_or_nothing, convert_if_not_null
export length_zt, err_buf, check_err
export gtkdoc_const_url, gtkdoc_enum_url, gtkdoc_flags_url, gtkdoc_method_url,
       gtkdoc_func_url, gtkdoc_struc_url

export gtype_wrappers, GVariantDict, GBytes, GVariantType
export GValue, GParamSpec, GTypeModule, _GValue

Maybe(T) = Union{T,Nothing}

cfunction_(@nospecialize(f), r, a::Tuple) = cfunction_(f, r, Tuple{a...})

@generated function cfunction_(f, R::Type{rt}, A::Type{at}) where {rt, at<:Tuple}
    quote
        @cfunction($(Expr(:$,:f)), $rt, ($(at.parameters...),))
    end
end

# local function, handles Symbol and makes UTF8-strings easier
const AbstractStringLike = Union{AbstractString, Symbol}
bytestring(s) = String(s)
bytestring(s::Symbol) = s
function bytestring(s::Union{Cstring,Ptr{UInt8}}, own::Bool=false)
    str=unsafe_string(s)
    if own
        g_free(s)
    end
    str
end
function string_or_nothing(s,owns)
    (s == C_NULL) ? nothing : bytestring(s, owns)
end

function convert_if_not_null(t,o,owns)
    if o == C_NULL
        nothing
    else
        convert(t, o, owns)
    end
end

function find_leaf_type_if_not_null(o,owns)
    if o == C_NULL
        nothing
    else
        leaftype = GLib.find_leaf_type(o)
        convert(leaftype, o, owns)
    end
end

g_malloc(s::Integer) = ccall((:g_malloc, libglib), Ptr{Nothing}, (Csize_t,), s)
g_free(p::Ptr) = ccall((:g_free, libglib), Nothing, (Ptr{Nothing},), p)
g_free(p::Cstring) = ccall((:g_free, libglib), Nothing, (Cstring,), p)
g_strfreev(p) = ccall((:g_strfreev, libglib), Nothing, (Ptr{Ptr{Nothing}},), p)

gtkdoc_const_url(ns,name)="https://docs.gtk.org/$(ns)/const.$(name).html"
gtkdoc_enum_url(ns,name)="https://docs.gtk.org/$(ns)/enum.$(name).html"
gtkdoc_flags_url(ns,name)="https://docs.gtk.org/$(ns)/flags.$(name).html"
gtkdoc_struc_url(ns,name)="https://docs.gtk.org/$(ns)/struct.$(name).html"
gtkdoc_class_url(ns,class)="https://docs.gtk.org/$(ns)/class.$(class).html"
gtkdoc_method_url(ns,class,method)="https://docs.gtk.org/$(ns)/method.$(class).$(method).html"
gtkdoc_func_url(ns,func)="https://docs.gtk.org/$(ns)/func.$(func).html"

# related to array handling
function length_zt(arr::Ptr)
    if arr==C_NULL
        return 0
    end
    i=1
    while unsafe_load(arr,i)!=C_NULL
        i+=1
    end
    i-1
end

function nothing_to_null(x)
    x = x === nothing ? C_NULL : x
end

function check_undefref(p::Ptr)
    if p == C_NULL
        throw(UndefRefError())
    end
    p
end

# accessor generation
isgetter(m) = length(m.sig.parameters)==2
issetter(m) = length(m.sig.parameters)==3

function _extract_instance_type(m)
    tv, decls, file, line = Base.arg_decl_parts(m)
    # type unfortunately has a namespace attached
    p=split(decls[2][2],".")
    length(p)==0 && error("Empty instance type in accessor generation for $m: maybe skip this one?")
    length(p)>3 && error("Too many namespaces in accessor generation for $m.")
    p
end

# for an instance method in `G_`, generate a getter method
function gen_getter(func,v,m)
    p=_extract_instance_type(m)
    t=Symbol(p[end]) # the type name
    return :($v(x::$t)=G_.$func(x))
end

# for an instance method in `G_`, generate a setter method
function gen_setter(func,v,m)
    p=_extract_instance_type(m)
    t=Symbol(p[end]) # the type name
    return :($v(x::$t,y)=G_.$func(x,y))
end

function Base.:(==)(b::T, i::Integer) where T<:BitFlag
    Integer(b) == i
end

function Base.:(==)(i::Integer, b::T) where T<:BitFlag
    Integer(b) == i
end

include("glist.jl")
include("gtype.jl")

eval(include("../gen/glib_consts"))

global const lib_version = VersionNumber(
      MAJOR_VERSION,
      MINOR_VERSION,
      MICRO_VERSION)

include("gvalues.jl")

eval(include("../gen/glib_structs"))

include("gvariant.jl")
include("gerror.jl")
include("arrays.jl")
include("hashtable.jl")

include("signals.jl")

eval(include("../gen/gobject_structs"))
eval(include("../gen/gio_structs"))

module G_

using Glib_jll

using ..GLib

import Base: convert, copy, run

eval(include("../gen/glib_methods"))
eval(include("../gen/glib_functions"))
eval(include("../gen/gobject_methods"))
eval(include("../gen/gobject_functions"))
eval(include("../gen/gio_methods"))
eval(include("../gen/gio_functions"))

end

include("gobject.jl")
include("listmodel.jl")
include("loop.jl")
include("actions.jl")

const exiting = Ref(false)
function __init__()
    global JuliaClosureMarshal = @cfunction(GClosureMarshal, Nothing,
        (Ptr{Nothing}, Ptr{GValue}, Cuint, Ptr{GValue}, Ptr{Nothing}, Ptr{Nothing}))
    exiting[] = false
    atexit(() -> (exiting[] = true))
    __init__gtype__()
    __init__gmainloop__()
    nothing
end

end
