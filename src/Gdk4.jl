export _GdkRGBA, _GdkRectangle
export keyval

keyval(name::AbstractString) = G_.keyval_from_name(name)

function GdkRGBA(r,g,b,a = 1.0)
   s=_GdkRGBA(r,g,b,a)
   r=ccall((:gdk_rgba_copy, libgtk4), Ptr{_GdkRGBA}, (Ptr{_GdkRGBA},), Ref(s))
   GdkRGBA(r)
end

function GdkRGBA(rgba::AbstractString)
   r=GdkRGBA(0,0,0,0)
   b=G_.parse(r,rgba)
   if !b
      error("Unable to parse $rgba into a GdkRGBA")
   end
   r
end

convert(::Type{RGBA}, gcolor::_GdkRGBA) = RGBA(gcolor.red, gcolor.green, gcolor.blue, gcolor.alpha)
convert(::Type{GdkRGBA}, color::Colorant) = GdkRGBA(red(color), green(color), blue(color), alpha(color))

Base.show(io::IO, c::GdkRGBA) = print(io,"GdkRGBA(\""*G_.to_string(c)*"\")")

## GdkCursor

GdkCursor(name::AbstractString; kwargs...) = GdkCursor(name, nothing; kwargs...)
function GdkCursor(texture::GdkTexture, hotspot_x::Integer, hotspot_y::Integer; kwargs...)
   GdkCursor(texture, hotspot_x, hotspot_y, nothing; kwargs...)
end

## GdkDisplay

"""
    GdkDisplay()

Get the default `GdkDisplay`.

Related GDK function: [`gdk_display_get_default`()]($(gtkdoc_method_url("gdk4","Display","get_default")))
"""
GdkDisplay() = G_.get_default() # returns default display
GdkDisplay(name) = G_.open(name)

## GdkMonitor

function size(m::GdkMonitor)
   r=G_.get_geometry(m)
   (r.width,r.height)
end

"""
    monitors()

Returns a list of `GdkMonitor`s for the default `GdkDisplay`, or `nothing` if none
are found.

Related GDK function: [`gdk_display_get_monitors`()]($(gtkdoc_method_url("gdk4","Display","get_monitors")))
"""
function monitors()
    d=GdkDisplay()
    G_.get_monitors(d)
end

## GdkClipboard

function set_text(c::GdkClipboard, str::AbstractString)
    ccall((:gdk_clipboard_set_text, libgtk4), Nothing, (Ptr{GObject}, Cstring), c, str)
end

## GdkTexture

size(t::GdkTexture) = (G_.get_width(t),G_.get_height(t))

const color_formats = Dict(ColorTypes.RGB{N0f8}=>MemoryFormat_R8G8B8,
                           ColorTypes.BGR{N0f8}=>MemoryFormat_B8G8R8,
                           ColorTypes.RGBA{N0f8}=>MemoryFormat_R8G8B8A8,
                           ColorTypes.ARGB{N0f8}=>MemoryFormat_A8R8G8B8,
                           ColorTypes.ABGR{N0f8}=>MemoryFormat_A8B8G8R8,
                           ColorTypes.BGRA{N0f8}=>MemoryFormat_B8G8R8A8,
                           ColorTypes.RGB{N0f16}=>MemoryFormat_R16G16B16,
                           ColorTypes.RGBA{N0f16}=>MemoryFormat_R16G16B16A16,
                           ColorTypes.Gray{N0f8}=>MemoryFormat_G8,
                           ColorTypes.Gray{N0f16}=>MemoryFormat_G16,
                           ColorTypes.GrayA{N0f8}=>MemoryFormat_G8A8,
                           ColorTypes.GrayA{N0f16}=>MemoryFormat_G16A16,
                           )

const color_formats_premultiplied = Dict(ColorTypes.RGBA{N0f8}=>MemoryFormat_R8G8B8A8_PREMULTIPLIED,
                           ColorTypes.ARGB{N0f8}=>MemoryFormat_A8R8G8B8_PREMULTIPLIED,
                           ColorTypes.BGRA{N0f8}=>MemoryFormat_B8G8R8A8_PREMULTIPLIED,
                           ColorTypes.RGBA{N0f16}=>MemoryFormat_R16G16B16A16_PREMULTIPLIED,
                           ColorTypes.GrayA{N0f8}=>MemoryFormat_G8A8_PREMULTIPLIED,
                           ColorTypes.GrayA{N0f16}=>MemoryFormat_G16A16_PREMULTIPLIED,
)

imgformatsupported(img) = eltype(img) in keys(color_formats)

"""
    GdkMemoryTexture(img::Array, tp = true)

Creates a `GdkMemoryTexture`, copying an image array. If `tp` is set to true,
the image will be transposed before copying so that the texture's orientation
when displayed by GTK widgets like `GtkPicture` will match how the image is
displayed in Julia apps like ImageShow.
"""
function GdkMemoryTexture(img::AbstractArray, tp = true)
    f = if imgformatsupported(img)
        color_formats[eltype(img)]
    else
        error("format not supported") # could also convert the image
    end
    img = tp ? img' : img
    b=GLib.GBytes(img)
    GdkMemoryTexture(size(img)[1], size(img)[2], f, b, sizeof(eltype(img))*size(img)[1])
end

function toarray(::Type{T}, t::GdkTexture, td::GdkTextureDownloader) where T
    ua = Vector{UInt8}(undef,sizeof(T)*size(t)[1]*size(t)[2])
    G_.download_into(td,ua,sizeof(T)*size(t)[1])
    arr = collect(reshape(reinterpret(T, ua),reverse(size(t))))
    arr'
end

function toarray(t::GdkTexture)
    td = GdkTextureDownloader(t)
    f = G_.get_format(td)
    for (k,v) in color_formats
        if v == f
            return toarray(k,t,td)
        end
    end
    for (k,v) in color_formats_premultiplied
        if v == f
            return toarray(k,t,td)
        end
    end
    error("no suitable format found")
end

function glib_ref(x::Ptr{GdkEvent})
    ccall((:gdk_event_ref, libgtk4), Nothing, (Ptr{GdkEvent},), x)
end
function glib_unref(x::Ptr{GdkEvent})
    ccall((:gdk_event_unref, libgtk4), Nothing, (Ptr{GdkEvent},), x)
end

