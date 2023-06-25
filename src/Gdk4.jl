export _GdkRGBA, _GdkRectangle
export keyval

keyval(name::AbstractString) = G_.keyval_from_name(name)

function GdkRGBA(r,g,b,a = 1.0)
   s=_GdkRGBA(r,g,b,a)
   r=ccall((:gdk_rgba_copy, libgtk4), Ptr{GdkRGBA}, (Ptr{_GdkRGBA},), Ref(s))
   GdkRGBA(r)
end

function GdkRGBA(rgba::AbstractString)
   r=GdkRGBA(0,0,0,0)
   b=G_.parse(r,rgba)
   if !b
      error("Unable to parse into a color")
   end
   r
end

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
