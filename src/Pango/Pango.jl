module Pango

using ..GLib
using Glib_jll
using Pango_jll

import Base: convert, copy
import CEnum: @cenum, CEnum
import BitFlags: @bitflag, BitFlag

eval(include("../gen/pango_consts"))
eval(include("../gen/pango_structs"))

include("Cairo.jl")

using .Cairo

module G_

import Base: copy

using Pango_jll, Glib_jll

using ..GLib
using ..Pango
using ..Pango.Cairo

eval(include("../gen/pango_methods"))
eval(include("../gen/pango_functions"))

eval(include("../gen/pangocairo_functions"))

end

# define accessor methods
for func in filter(x->startswith(string(x),"get_"),Base.names(G_,all=true))
    ms=methods(getfield(Pango.G_,func))
    v=Symbol(string(func)[5:end])
    for m in ms
        GLib.isgetter(m) || continue
        eval(GLib.gen_getter(func,v,m))
    end
end

for func in filter(x->startswith(string(x),"set_"),Base.names(G_,all=true))
    ms=methods(getfield(Pango.G_,func))
    v=Symbol(string(func)[5:end])
    for m in ms
        GLib.issetter(m) || continue
        eval(GLib.gen_setter(func,v,m))
    end
end

function __init__()
   gtype_wrapper_cache_init()
   gboxed_cache_init()
end

default_font_map() = Pango.G_.font_map_get_default()
PangoLayout(cr::cairoContext) = Pango.G_.create_layout(cr)
PangoLayout(c::PangoContext) = Pango.G_.Layout_new(c)
PangoContext(fm::PangoFontMap) = Pango.G_.create_context(fm)

end
