module Pango

using ..GLib
using Glib_jll
using Pango_jll
using CEnum

import Base: convert, copy

eval(include("../gen/pango_consts"))
eval(include("../gen/pango_structs"))

eval(include("../gen/pango_methods"))
eval(include("../gen/pango_functions"))

include("Cairo.jl")
include("PangoCairo.jl")

function __init__()
   gtype_wrapper_cache_init()
   gboxed_cache_init()
end

end
