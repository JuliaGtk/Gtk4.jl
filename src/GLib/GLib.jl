module GLib

if isdefined(Base, :Experimental) && isdefined(Base.Experimental, Symbol("@optlevel"))
    @eval Base.Experimental.@optlevel 1
end

# Import `libglib` and `libgobject`
using Glib_jll

import Base: convert, copy, show, size, length, getindex, setindex!, get,
             iterate, eltype, isempty, ndims, stride, strides, popfirst!,
             empty!, append!, reverse!, pushfirst!, pop!, push!, splice!, insert!, deleteat!, delete!,
             sigatomic_begin, sigatomic_end, Sys.WORD_SIZE, unsafe_convert,
             getproperty, setproperty!, propertynames, getindex, setindex!, print, replace

using Libdl
using CEnum, BitFlags

export Maybe

export GList, GSList, glist_iter, _GSList, _GList, GError, GVariant, GType, GBoxed
export GObject, GInitiallyUnowned, GInterface, GTypeInterface, _GTypeInterface, GParam
export GByteArray, GHashTable, GPtrArray
export g_timeout_add, g_idle_add, @idle_add, @guarded, @sigatom
export cfunction_
export gobject_ref, signal_connect, signal_emit, signal_handler_disconnect
export signal_handler_block, signal_handler_unblock
export add_action, add_stateful_action

export get_gtk_property, set_gtk_property!, gtk_propertynames, bind_property, unbind_property

export bytestring

export length_zt, err_buf, check_err

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

g_malloc(s::Integer) = ccall((:g_malloc, libglib), Ptr{Nothing}, (Csize_t,), s)
g_free(p::Ptr) = ccall((:g_free, libglib), Nothing, (Ptr{Nothing},), p)
g_free(p::Cstring) = ccall((:g_free, libglib), Nothing, (Cstring,), p)
g_strfreev(p) = ccall((:g_strfreev, libglib), Nothing, (Ptr{Ptr{Nothing}},), p)

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

function check_undefref(p::Ptr)
    if p == C_NULL
        throw(UndefRefError())
    end
    p
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
