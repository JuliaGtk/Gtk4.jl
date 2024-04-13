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

convert(::Type{RGBA}, gcolor::Gtk4._GdkRGBA) = RGBA(gcolor.red, gcolor.green, gcolor.blue, gcolor.alpha)
convert(::Type{Gtk4.GdkRGBA}, color::Colorant) = Gtk4.GdkRGBA(red(color), green(color), blue(color), alpha(color))

## GdkCursor

GdkCursor(name::AbstractString; kwargs...) = GdkCursor(name, nothing; kwargs...)
function GdkCursor(texture::GdkTexture, hotspot_x::Integer, hotspot_y::Integer; kwargs...)
   GdkCursor(texture, hotspot_x, hotspot_y, nothing; kwargs...)
end

## GdkDisplay

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
"""
function monitors()
    d=GdkDisplay()
    G_.get_monitors(d)
end

const color_formats = Dict(ColorTypes.RGB{N0f8}=>Gtk4.MemoryFormat_R8G8B8,
                           ColorTypes.BGR{N0f8}=>Gtk4.MemoryFormat_B8G8R8,
                           ColorTypes.RGBA{N0f8}=>Gtk4.MemoryFormat_R8G8B8A8,
                           ColorTypes.ARGB{N0f8}=>Gtk4.MemoryFormat_A8R8G8B8,
                           ColorTypes.ABGR{N0f8}=>Gtk4.MemoryFormat_A8B8G8R8,
                           ColorTypes.BGRA{N0f8}=>Gtk4.MemoryFormat_B8G8R8A8,
                           ColorTypes.RGB{N0f16}=>Gtk4.MemoryFormat_R16G16B16,
                           ColorTypes.RGBA{N0f16}=>Gtk4.MemoryFormat_R16G16B16A16,
                          )

"""
    GdkMemoryTexture(img::Array)

Creates a `GdkMemoryTexture`, copying an image array.
"""
function GdkMemoryTexture(img::Array)
    b=Gtk4.GLib.GBytes(img)
    f = if eltype(img) in keys(color_formats)
        color_formats[eltype(img)]
    else
        error("format not supported") # could also convert the image
    end
    GdkMemoryTexture(size(img)[1], size(img)[2], f, b, sizeof(eltype(img))*size(img)[1])
end
GdkMemoryTexture(img::AbstractArray) = GdkMemoryTexture(collect(img))

function glib_ref(x::Ptr{GdkEvent})
    ccall((:gdk_event_ref, libgtk4), Nothing, (Ptr{GdkEvent},), x)
end
function glib_unref(x::Ptr{GdkEvent})
    ccall((:gdk_event_unref, libgtk4), Nothing, (Ptr{GdkEvent},), x)
end
