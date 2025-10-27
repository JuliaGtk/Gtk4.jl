module Graphene

using GObjects
const GLib = GObjects
@static if GObjects.libdir == ""
    using Graphene_jll
else
    const libgraphene = joinpath(GObjects.libdir, "libgraphene-1.0.so")
end

import Base: convert, length, getindex, iterate, unsafe_convert

import CEnum: @cenum, CEnum

include("gen/graphene_consts")
include("gen/graphene_structs")

export _GrapheneRect, _GraphenePoint, _GrapheneMatrix, _GrapheneVec4, _GrapheneVec3, _GrapheneSize, _GraphenePoint3D

module G_

using ..GLib
using ..Graphene
using ..Graphene: libgraphene

include("gen/graphene_methods")
#include("gen/graphene_functions")

end

_GrapheneRect(x::Number,y::Number,w::Number,h::Number) = _GrapheneRect(_GraphenePoint(x,y),_GrapheneSize(w,h))
# this constructor returns a RefValue{_GrapheneRect}, which is GrapheneRectLike
# This seems to result in one less (Julia) allocation than constructing a Ptr{GrapheneRect} by calling "alloc", "init"
GrapheneRect(x::Number,y::Number,w::Number,h::Number) = Ref(_GrapheneRect(x,y,w,h))

GraphenePoint(x::Number, y::Number) = Ref(_GraphenePoint(x,y))

function __init__()
   gtype_wrapper_cache_init()
   gboxed_cache_init()
end

end
