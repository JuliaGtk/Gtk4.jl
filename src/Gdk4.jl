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

## GdkTexture

GdkTexture(p::GdkPixbuf) = G_.Texture_new_for_pixbuf(p)

## GdkCursor

function GdkCursor(name::AbstractString, fallback = nothing)
   G_.Cursor_new_from_name(name, fallback)
end
function GdkCursor(texture::GdkTexture, hotspot_x::Integer, hotspot_y::Integer, fallback = nothing)
   G_.Cursor_new_from_texture(texture, hotspot_x, hotspot_y, fallback)
end

## GdkMonitor

function size(m::GdkMonitor)
   r=G_.get_geometry(m)
   (r.width,r.height)
end
