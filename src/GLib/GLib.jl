module GLib

if isdefined(Base, :Experimental) && isdefined(Base.Experimental, Symbol("@optlevel"))
    @eval Base.Experimental.@optlevel 1
end

# Import `libglib` and `libgobject`
using Glib_jll

import Base: convert, copy, show, size, length, getindex, setindex!, get,
             iterate, eltype, isempty, ndims, stride, strides, popfirst!,
             empty!, append!, reverse!, pushfirst!, pop!, push!, splice!, insert!, deleteat!,
             sigatomic_begin, sigatomic_end, Sys.WORD_SIZE, unsafe_convert,
             getproperty, setproperty!, propertynames, getindex, setindex!, print, replace

using Libdl
using CEnum

export Maybe

export GList, GSList, glist_iter, _GSList, _GList, GError, GVariant, GType, GBoxed
export GObject, GInitiallyUnowned, GInterface, GTypeInterface
export GByteArray, GHashTable, GPtrArray
export g_timeout_add, g_idle_add, @idle_add
export @sigatom, cfunction_
export gobject_ref, signal_connect

export get_gtk_property, set_gtk_property!

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

include("glist.jl")
include("gvariant.jl")
include("gtype.jl")
include("gvalues.jl")

eval(include("../gen/glib_consts"))
using .Constants

eval(include("../gen/glib_structs"))

include("gerror.jl")
include("arrays.jl")
include("hashtable.jl")

include("signals.jl")

eval(include("../gen/glib_methods"))
eval(include("../gen/glib_functions"))

eval(include("../gen/gobject_structs"))
eval(include("../gen/gobject_methods"))
eval(include("../gen/gobject_functions"))

eval(include("../gen/gio_structs"))
eval(include("../gen/gio_methods"))
eval(include("../gen/gio_functions"))

end
