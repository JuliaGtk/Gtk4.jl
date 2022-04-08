module Gdk4

using GTK4_jll

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

import Base: convert, copy

eval(include("gen/gdk4_methods"))
eval(include("gen/gdk4_functions"))

end

keyval(name::AbstractString) = G_.keyval_from_name(name)

function __init__()
   gtype_wrapper_cache_init()
   gboxed_cache_init()
end

end
