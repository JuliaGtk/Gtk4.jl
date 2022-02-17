module PangoCairo

using ..GLib
using ..Pango
using ..Cairo

using Pango_jll

eval(include("../gen/pangocairo_functions"))

end
