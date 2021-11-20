module Gsk4

using GLib
using GLib.MutableTypes
using Pango
using Pango.Cairo
using GdkPixbufLib
using ..Gdk4

eval(include("gen/gsk4_consts"))
eval(include("gen/gsk4_structs"))

#eval(include("gen/gtk4_methods"))
#eval(include("gen/gtk4_functions"))

function __init__()
   gtype_wrapper_cache_init()
end

end
