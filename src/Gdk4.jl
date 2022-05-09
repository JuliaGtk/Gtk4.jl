module Gdk4

using GTK4_jll, Glib_jll

using ..GLib
using ..Pango
using ..Pango.Cairo
using ..GdkPixbufLib

import Base: unsafe_convert

eval(include("gen/gdk4_consts"))
eval(include("gen/gdk4_structs"))

export _GdkRGBA, _GdkRectangle
export keyval

module G_

using GTK4_jll

using ..GLib
using ..Gdk4
using ..Pango.Cairo
using ..GdkPixbufLib

import Base: convert, copy, size

eval(include("gen/gdk4_methods"))
eval(include("gen/gdk4_functions"))

end

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

function size(m::GdkMonitor)
   r=G_.get_geometry(m)
   (r.width,r.height)
end

function __init__()
   gtype_wrapper_cache_init()
   gboxed_cache_init()
end

end
