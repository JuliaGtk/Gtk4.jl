module Graphene

using GObjects
const GLib = GObjects
using Graphene_jll

import Base: convert, length, getindex, iterate, unsafe_convert

import CEnum: @cenum, CEnum

eval(include("gen/graphene_consts"))
eval(include("gen/graphene_structs"))

export _GrapheneRect, _GraphenePoint, _GrapheneMatrix, _GrapheneVec4, _GrapheneVec3, _GrapheneSize, _GraphenePoint3D

module G_

using Graphene_jll

using ..GLib
using ..Graphene

eval(include("gen/graphene_methods"))
#eval(include("gen/graphene_functions"))

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
