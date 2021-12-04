module Gdk4

using GLib
using Pango.Cairo
using GdkPixbufLib

eval(include("gen/gdk4_consts"))
eval(include("gen/gdk4_structs"))

export GdkRGBA

eval(include("gen/gdk4_methods"))
eval(include("gen/gdk4_functions"))

function __init__()
   gtype_wrapper_cache_init()
   gboxed_cache_init()
end

end
