# Minimal module for GLib -- used by GI, so it doesn't include any automatically
# generated structs or methods.

module GLibBase

using Glib_jll

import Base: convert, size, length, getindex, setindex!, get,
             iterate, eltype, isempty, ndims, stride, strides, popfirst!,
             empty!, append!, reverse!, pushfirst!, pop!, push!, splice!,
             sigatomic_begin, sigatomic_end, Sys.WORD_SIZE, unsafe_convert, getproperty,
             getindex, setindex!

using Libdl

export GInterface, GType, GObject, GBoxed
export GEnum, GError, GValue, gvalue, g_type
export GHashTable, GByteArray, GArray, GPtrArray
export GList, glist_iter, _GSList, _GList
export GConnectFlags
export cfunction_


cfunction_(@nospecialize(f), r, a::Tuple) = cfunction_(f, r, Tuple{a...})

@generated function cfunction_(f, R::Type{rt}, A::Type{at}) where {rt, at<:Tuple}
    quote
        @cfunction($(Expr(:$,:f)), $rt, ($(at.parameters...),))
    end
end

# local function, handles Symbol and makes UTF8-strings easier
const  AbstractStringLike = Union{AbstractString, Symbol}
bytestring(s) = String(s)
bytestring(s::Symbol) = s
bytestring(s::Ptr{UInt8}) = unsafe_string(s)
# bytestring(s::Ptr{UInt8}, own::Bool=false) = unsafe_string(s)

g_malloc(s::Integer) = ccall((:g_malloc, libglib), Ptr{Nothing}, (Csize_t,), s)
g_free(p::Ptr) = ccall((:g_free, libglib), Nothing, (Ptr{Nothing},), p)

include("glist.jl")

mutable struct GVariant
    handle::Ptr{GVariant}
end

convert(::Type{GVariant}, unbox::Ptr{GVariant}) = GVariant(unbox)
unsafe_convert(::Type{Ptr{GVariant}}, w::GVariant) = getfield(w, :handle)

include("gtype.jl")

mutable struct GHashTable <: GBoxed
    handle::Ptr{GHashTable}
    begin
        (GLibBase.g_type(::Type{T}) where T <: GHashTable) = begin
                ccall((:g_hash_table_get_type, libgobject), GType, ())
            end
        function GHashTable(ref::Ptr{GHashTable}, own::Bool = false)
            gtype = ccall((:g_hash_table_get_type, libgobject), GType, ())
            own || ccall((:g_boxed_copy, libgobject), Nothing, (GType, Ptr{GHashTable}), gtype, ref)
            x = new(ref)
            finalizer((x::GHashTable->begin
                        ccall((:g_boxed_free, libgobject), Nothing, (GType, Ptr{GHashTable}), gtype, x.handle)
                    end), x)
        end
    end
end

struct GArray <: GBoxed
    data::Ptr{UInt8}
    len::UInt32
end

mutable struct GByteArray <: GBoxed
    handle::Ptr{GByteArray}
end

struct _GByteArray
    data::Ptr{UInt8}
    len::UInt32
end

struct GPtrArray <: GBoxed
    pdata::Ptr{Nothing}
    len::UInt32
end

struct GValue
    g_type::GType
    field2::UInt64
    field3::UInt64
    GValue() = new(0, 0, 0)
end

include("gerror.jl")

export @g_type_delegate
macro g_type_delegate(eq)
    @assert isa(eq, Expr) && eq.head == :(=) && length(eq.args) == 2
    new = eq.args[1]
    real = eq.args[2]
    newleaf = esc(Symbol(string(new, __module__.suffix)))
    realleaf = esc(Symbol(string(real, __module__.suffix)))
    new = esc(new)
    macroreal = QuoteNode(Symbol(string('@', real)))
    quote
        $newleaf = $realleaf
        macro $new(args...)
            Expr(:macrocall, $macroreal, map(esc, args)...)
        end
    end
end

end # module
