using GI, EzXML
GI.prepend_search_path("/usr/lib64/girepository-1.0")

path="../src/gen"

ns = GINamespace(:Graphene,"1.0")

GI.export_consts!(ns, path, "graphene"; export_constants = false)

## structs

disguised = Symbol[]
struct_skiplist=vcat(disguised, Symbol[])
first_list=[:Simd4F,:Vec3,:Simd4X4F,:Size]

struct_skiplist = GI.export_struct_exprs!(ns,path, "graphene", struct_skiplist, [:Frustum,:Quad]; first_list = first_list)
GI.export_methods!(ns,path,"graphene"; struct_skiplist = struct_skiplist)
GI.export_functions!(ns,path,"graphene")

