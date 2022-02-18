module Graphene

using ..GLib
using CEnum

eval(include("gen/graphene_consts"))
eval(include("gen/graphene_structs"))

#eval(include("gen/graphene_methods"))
#eval(include("gen/graphene_functions"))

function __init__()
   gtype_wrapper_cache_init()
   gboxed_cache_init()
end

end
