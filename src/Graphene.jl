module Graphene

using ..GLib
using Graphene_jll

import CEnum: @cenum, CEnum

eval(include("gen/graphene_consts"))
eval(include("gen/graphene_structs"))

export _GrapheneRect, _GraphenePoint, _GrapheneMatrix, _GrapheneVec4, _GrapheneVec3, _GrapheneSize, _GraphenePoint3D

#eval(include("gen/graphene_methods"))
#eval(include("gen/graphene_functions"))

function __init__()
   gtype_wrapper_cache_init()
   gboxed_cache_init()
end

end
