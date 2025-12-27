module GdkPixbufLib

using ..GLib
using Glib_jll
using gdk_pixbuf_jll
using Librsvg_jll
using JLLWrappers
using Scratch
using ColorTypes
import FixedPointNumbers: N0f8

import Base: convert, size, eltype, getindex, setindex!
import CEnum: @cenum
import BitFlags: @bitflag
import Graphics: width, height

export GdkPixbuf, GdkPixbufAnimation
export width, height, slice

const Index{I<:Integer} = Union{I, AbstractVector{I}}

include("gen/gdkpixbuf_consts")
include("gen/gdkpixbuf_structs")

module G_

using gdk_pixbuf_jll

using ..GLib
using ..GdkPixbufLib
using ..GdkPixbufLib: Colorspace, InterpType, PixbufError, PixbufRotation

import Base: convert, copy

include("gen/gdkpixbuf_methods")
include("gen/gdkpixbuf_functions")

end

# define accessor methods
let skiplist = [ :file_info ]
    for func in filter(x->startswith(string(x),"get_"),Base.names(G_,all=true))
        ms=methods(getfield(GdkPixbufLib.G_,func))
        v=Symbol(string(func)[5:end])
        v in skiplist && continue
        for m in ms
            GLib.isgetter(m) || continue
            eval(GLib.gen_getter(func,v,m))
        end
    end

    for func in filter(x->startswith(string(x),"set_"),Base.names(G_,all=true))
        ms=methods(getfield(GdkPixbufLib.G_,func))
        v=Symbol(string(func)[5:end])
        v in skiplist && continue
        for m in ms
            GLib.issetter(m) || continue
            eval(GLib.gen_setter(func,v,m))
        end
    end
end

const lib_version = VersionNumber(
      PIXBUF_MAJOR,
      PIXBUF_MINOR,
      PIXBUF_MICRO)

struct RGB
    r::UInt8; g::UInt8; b::UInt8
    RGB(r, g, b) = new(r, g, b)
end
convert(::Type{RGB}, x::Unsigned) = RGB(UInt8(x), UInt8(x >> 8), UInt8(x >> 16))
convert(::Type{U}, x::RGB) where {U <: Unsigned} = convert(U, (x.r) | (x.g >> 8) | (x.b >> 16))
function convert(::Type{RGB}, x::Colorant)
    c = ColorTypes.RGB{N0f8}(x)
    RGB(reinterpret(UInt8,red(c)),reinterpret(UInt8,green(c)),reinterpret(UInt8,blue(c)))
end

struct RGBA
    r::UInt8; g::UInt8; b::UInt8; a::UInt8
    RGBA(r, g, b, a) = new(r, g, b, a)
end
convert(::Type{RGBA}, x::Unsigned) = RGBA(UInt8(x), UInt8(x >> 8), UInt8(x >> 16), UInt8(x >> 24))
convert(::Type{U}, x::RGBA) where {U <: Unsigned} = convert(U, (x.r) | (x.g >> 8) | (x.b >> 16) | (x.a >> 24))
function convert(::Type{RGBA}, x::Colorant)
    c = ColorTypes.RGBA{N0f8}(x)
    RGBA(reinterpret(UInt8,red(c)),reinterpret(UInt8,green(c)),reinterpret(UInt8,blue(c)),reinterpret(UInt8,alpha(c)))
end

# Example constructors:
#MatrixStrided(width = 10, height = 20)
#MatrixStrided(p, width = 10, height = 20, rowstride = 30)
#MatrixStrided(p, rowstride = 20, nbytes = 100)
#MatrixStrided(p, width = 10, height = 20, rowstride = 30, nbytes = 100)
mutable struct MatrixStrided{T} <: AbstractMatrix{T}
    # immutable, except that we need the GC root for p
    p::Ptr{T}
    nbytes::Int
    rowstride::Int
    width::Int
    height::Int
    function MatrixStrided{T}(p::Ptr = C_NULL; nbytes = -1, rowstride = -1, width = -1, height = -1) where T
        if width == -1
            @assert(rowstride > 0, "MatrixStrided rowstride must be > 0 if width not given")
            width = div(rowstride, sizeof(T))
        end
        @assert(width > 0, "MatrixStrided width must be > 0")
        if height == -1
            @assert nbytes > 0 && rowstride > 0, "MatrixStrided nbytes and rowstride must be > 0 if height not given"
            height = div(nbytes + rowstride - 1, rowstride)
        end
        @assert(height > 0, "MatrixStrided height must be > 0")
        rowstride_req = width * sizeof(T)
        if rowstride == -1
            @assert(p == C_NULL, "MatrixStrided rowstride must be given")
            rowstride_preferred = (rowstride_req + 3) & ~3
            nbytes_preferred = rowstride_preferred * (height - 1) + width * sizeof(T)
            if p == C_NULL || nbytes > nbytes_preferred
                rowstride = rowstride_preferred
            else
                rowstride = rowstride_req
            end
        else
            @assert(rowstride >= rowstride_req, "MatrixStrided rowstride must be larger than the width")
        end
        nbytes_req = rowstride * (height - 1) + width * sizeof(T)
        if nbytes == -1
            nbytes = nbytes_req
        else
            @assert(nbytes >= nbytes_req, "MatrixStrided nbytes too small to contain array")
        end
        if p == C_NULL
            a = new{T}(g_malloc(nbytes), nbytes, rowstride, width, height)
            finalize(a, a -> g_free(a.p))
        else
            a = new{T}(p, nbytes, rowstride, width, height)
        end
        a
    end
end
MatrixStrided(p::Ptr{T}; kwargs...) where {T} = MatrixStrided{T}(p; kwargs...)
MatrixStrided(::Type{T}; kwargs...) where {T} = MatrixStrided{T}(; kwargs...)
function copy(a::MatrixStrided{T}) where T
    a2 = MatrixStrided{T}(a.nbytes, a.rowstride, a.width, a.height)
    unsafe_copyto!(a2.p, a.p, a.nbytes)
    a2
end
function getindex(a::MatrixStrided{T}, x::Integer, y::Integer) where T
    @assert(1 <= minimum(x) && maximum(x) <= width(a), "MatrixStrided: x index must be inbounds")
    @assert(1 <= minimum(y) && maximum(y) <= height(a), "MatrixStrided: y index must be inbounds")
    return unsafe_load(a.p + (x - 1) * sizeof(T) + (y - 1) * a.rowstride)
end
function getindex(a::MatrixStrided{T}, x::Index, y::Index) where T
    @assert(1 <= minimum(x) && maximum(x) <= width(a), "MatrixStrided: x index must be inbounds")
    @assert(1 <= minimum(y) && maximum(y) <= height(a), "MatrixStrided: y index must be inbounds")
    z = Matrix{T}(undef, length(x), length(y))
    rs = a.rowstride
    st = sizeof(T)
    p = a.p
    lenx = length(x)
    for zj = 1:length(y)
        j = (y[zj]-1) * rs
        for zi = 1:lenx
            i = (x[zi]-1) * st
            z[zi, zj] = unsafe_load(p + i + j)
        end
    end
    return z
end
function setindex!(a::MatrixStrided{T}, z, x::Integer, y::Integer) where T
    @assert(1 <= minimum(x) && maximum(x) <= width(a), "MatrixStrided: x index must be inbounds")
    @assert(1 <= minimum(y) && maximum(y) <= height(a), "MatrixStrided: y index must be inbounds")
    unsafe_store!(a.p + (x - 1) * sizeof(T) + (y - 1) * a.rowstride, convert(T, z))
    a
end
function setindex!(a::MatrixStrided{T}, z, x::Index, y::Index) where T
    @assert(1 <= minimum(x) && maximum(x) <= width(a), "MatrixStrided: x index must be inbounds")
    @assert(1 <= minimum(y) && maximum(y) <= height(a), "MatrixStrided: y index must be inbounds")
    rs = a.rowstride
    st = sizeof(T)
    p = a.p
    lenx = length(x)
    if !isa(z, AbstractMatrix)
        elem = convert(T, z)::T
        for zj = 1:length(y)
            j = (y[zj]-1) * rs + p
            for zi = 1:lenx
                i = (x[zi]-1) * st
                unsafe_store!(j + i, elem)
            end
        end
    else
        for zj = 1:length(y)
            j = (y[zj]-1) * rs + p
            for zi = 1:lenx
                i = (x[zi]-1) * st
                elem = convert(T, z[zi, zj])::T
                unsafe_store!(j + i, elem)
            end
        end
    end
    a
end
Base.fill!(a::MatrixStrided{T}, z) where {T} = setindex!(a, convert(T, z), 1:width(a), 1:height(a))
width(a::MatrixStrided) = a.width
height(a::MatrixStrided) = a.height
size(a::MatrixStrided, i::Integer) = (i == 1 ? width(a) : (i == 2 ? height(a) : 1))
size(a::MatrixStrided) = (width(a), height(a))
# next line was causing invalidations
# convert(::Type{P}, a::MatrixStrided) where {P <: Ptr} = convert(P, a.p)
bstride(a::MatrixStrided, i) = (i == 1 ? sizeof(eltype(a)) : (i == 2 ? a.rowstride : 0))
bstride(a, i) = stride(a, i) * sizeof(eltype(a))

function GdkPixbuf(width::Integer, height::Integer, has_alpha = true)
    G_.Pixbuf_new(Colorspace_RGB, has_alpha, 8, width, height)
end

gc_unref_gdkpixbufdata(::Ptr{Nothing},x) = GLib.gc_unref(x)
gc_ref_closure_gdkpixbufdata(x::T) where {T} = (GLib.gc_ref(x), @cfunction(gc_unref_gdkpixbufdata, Nothing, (Ptr{Nothing},Any)))

function GdkPixbuf(data::AbstractArray, has_alpha = false)
    local pixbuf::Ptr{GObject}
    if data !== nothing # RGB or RGBA array, packed however you wish
        alpha = convert(Bool, has_alpha)
        width = size(data, 1) * bstride(data, 1)/(3 + Int(alpha))
        height = size(data, 2)
        ref_data, deref_data = gc_ref_closure_gdkpixbufdata(data)
        pixbuf = ccall((:gdk_pixbuf_new_from_data, libgdkpixbuf), Ptr{GObject},
            (Ptr{Nothing}, Cint, Cint, Cint, Cint, Cint, Cint, Ptr{Cvoid}, Ptr{Nothing}),
            data, 0, alpha, 8, width, height, bstride(data, 2),
            deref_data, ref_data)
    end
    return GdkPixbufLeaf(pixbuf, true)
end

slice(img::GdkPixbuf, x, y) = G_.new_subpixbuf(img, first(x)-1, first(y)-1, length(x), length(y))
size(a::GdkPixbuf, i::Integer) = (i == 1 ? width(a) : (i == 2 ? height(a) : 1))
size(a::GdkPixbuf) = (width(a), height(a))
Base.ndims(::GdkPixbuf) = 2
function bstride(img::GdkPixbuf, i)
    if i == 1
        div(G_.get_bits_per_sample(img) * G_.get_n_channels(img) + 7, 8)
    elseif i == 2
        G_.get_rowstride(img)
    else
        return 0
    end
end
function eltype(img::GdkPixbuf)
    nbytes = div(G_.get_bits_per_sample(img) * G_.get_n_channels(img) + 7, 8)
    if nbytes == 3
        RGB
    elseif nbytes == 4
        RGBA
    else
        error("GdkPixbuf stride must be 3 or 4")
    end
end
function convert(::Type{MatrixStrided}, img::GdkPixbuf)
    MatrixStrided(
        convert(Ptr{eltype(img)}, ccall((:gdk_pixbuf_get_pixels, libgdkpixbuf), Ptr{Nothing}, (Ptr{GObject},), img)),
        width = width(img), height = height(img),
        rowstride = G_.get_rowstride(img))
end
getindex(img::GdkPixbuf, x::Index, y::Index) = convert(MatrixStrided, img)[x, y]
setindex!(img::GdkPixbuf, pix, x::Index, y::Index) = setindex!(convert(MatrixStrided, img), pix, x, y)
Base.fill!(img::GdkPixbuf, pix) = fill!(convert(MatrixStrided, img), pix)
#TODO: image transformations, rotations, compositing
# G_.flip -> Base.reverse

function query_pixbuf_loaders(dir::String;
                              extra_env::Vector{Pair{String,String}} = Pair{String,String}[])
    gpql = gdk_pixbuf_query_loaders()
    return readchomp(addenv(gpql, "GDK_PIXBUF_MODULEDIR" => dir, extra_env...))
end

function __init__()
    gtype_wrapper_cache_init()
    gboxed_cache_init()

    cache_dir = @get_scratch!("gdk-pixbuf-cache")
    treehash_cache_path = joinpath(cache_dir, "gdk_pixbuf_treehash.cache")
    loaders_cache_path = joinpath(cache_dir, "loaders.cache")
    gdk_pixbuf_treehash = basename(gdk_pixbuf_jll.artifact_dir)
    if !isfile(treehash_cache_path) || read(treehash_cache_path, String) != gdk_pixbuf_treehash
        open(loaders_cache_path, write=true) do io
            # Cache builtin gdx-pixbuf modules
            write(io, query_pixbuf_loaders(gdk_pixbuf_loaders_dir))
            println(io)

            # If Librsvg_jll is available, cache that one too
            if Librsvg_jll.is_available()
                librsvg_module_dir = dirname(Librsvg_jll.libpixbufloader_svg)
                write(io, query_pixbuf_loaders(librsvg_module_dir; extra_env = [
                    JLLWrappers.LIBPATH_env=>Librsvg_jll.LIBPATH[],
                ]))
                println(io)
            end
        end

        rm(treehash_cache_path; force=true)
        open(treehash_cache_path, write=true) do io
            write(io, gdk_pixbuf_treehash)
        end
    end

    # Point gdk to our cached loaders
    ENV["GDK_PIXBUF_MODULE_FILE"] = loaders_cache_path
end

end
