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

## object properties

for o in GI.get_all(ns,GI.GIObjectInfo)
    name=GI.get_name(o)
    println("object: $name")
    properties=GI.get_properties(o)
    for p in properties
        flags=GI.get_flags(p)
        tran=GI.get_ownership_transfer(p)
        println("property: ",GI.get_name(p)," ",tran)
        if GI.is_deprecated(p)
            continue
        end
        typ=GI.get_type(p)
        btyp=GI.get_base_type(typ)
        println(GI.get_name(p)," ",btyp)
        #try
            #fun=GI.create_method(m,GI.get_c_prefix(ns))
            #push!(exprs, fun)
            #global created+=1
        #catch NotImplementedError
        #    global not_implemented+=1
        #catch LoadError
        #    println("error")
        #end
    end
end


## functions

toplevel, exprs, exports = GI.output_exprs()

GI.all_functions!(exprs,ns)

GI.write_to_file(path,"graphene_functions",toplevel)
