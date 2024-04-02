using GI

path="../src/gen"

ns = GINamespace(:Graphene,"1.0")

GI.export_consts!(ns, path, "graphene"; export_constants = false)

## structs

disguised = Symbol[]
struct_skiplist=vcat(disguised, Symbol[])
first_list=[:Simd4F,:Vec3,:Simd4X4F,:Size]

struct_skiplist = GI.export_struct_exprs!(ns,path, "graphene", struct_skiplist, [:Frustum,:Quad]; first_list = first_list)

## struct methods

toplevel, exprs, exports = GI.output_exprs()

GI.all_struct_methods!(exprs,ns,struct_skiplist=struct_skiplist)

## object methods

skiplist=Symbol[]

# skips are to avoid method name collisions
GI.all_object_methods!(exprs,ns;skiplist=skiplist)

# skips are to avoid method name collisions
GI.all_interface_methods!(exprs,ns)

GI.write_to_file(path,"graphene_methods",toplevel)

GI.export_functions!(ns,path,"graphene")

