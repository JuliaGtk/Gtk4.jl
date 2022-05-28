module Gsk4

using GTK4_jll

using ..GLib
using ..Pango
using ..Pango.Cairo
using ..GdkPixbufLib
using ..Gdk4
using CEnum, BitFlags

eval(include("gen/gsk4_consts"))
eval(include("gen/gsk4_structs"))

#eval(include("gen/gsk4_methods"))
#eval(include("gen/gsk4_functions"))

function __init__()
   gtype_wrapper_cache_init()
   gboxed_cache_init()
end

end
