module Pango

using GObjects
const GLib = GObjects
using Glib_jll
using Pango_jll

import Base: convert, copy, length, getindex, iterate, unsafe_convert
import CEnum: @cenum, CEnum
import BitFlags: @bitflag, BitFlag

eval(include("../gen/pango_consts"))
eval(include("../gen/pango_structs"))

include("Cairo.jl")

eval(include("../gen/pangocairo_structs"))

using .Cairo

module G_

import Base: copy

using Pango_jll, Glib_jll

using GObjects
const GLib = GObjects
using ..Pango
using ..Pango.Cairo

eval(include("../gen/pango_methods"))
eval(include("../gen/pango_functions"))

eval(include("../gen/pangocairo_methods"))
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

default_font_map() = G_.font_map_get_default()
length(fm::PangoFontMap) = length(GListModel(fm))
getindex(fm::PangoFontMap, i::Integer) = getindex(GListModel(fm),i)
iterate(fm::PangoFontMap, i=0) = iterate(GListModel(fm), i)
eltype(::Type{PangoFontMap}) = PangoFontFamily
Base.keys(fm::PangoFontMap) = 1:length(fm)

length(ff::PangoFontFamily) = length(GListModel(ff))
getindex(ff::PangoFontFamily, i::Integer) = getindex(GListModel(ff),i)
iterate(ff::PangoFontFamily, i=0) = iterate(GListModel(ff), i)
eltype(::Type{PangoFontFamily}) = PangoFontFace
Base.keys(ff::PangoFontFamily) = 1:length(ff)

PangoFontDescription(s::AbstractString) = G_.font_description_from_string(s)
Base.show(io::IO, pfd::PangoFontDescription) = print(io, "PangoFontDescription(" * G_.to_string(pfd) * ")")

PangoLayout(cr::cairoContext) = G_.create_layout(cr)

PangoContext(fm::PangoFontMap) = G_.create_context(fm)
getindex(pc::PangoContext, fd::PangoFontDescription) = G_.load_font(pc, fd)

end
