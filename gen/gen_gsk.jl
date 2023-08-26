using GI

toplevel, exprs, exports = GI.output_exprs()

path="../src/gen"

ns = GINamespace(:Gsk,"4.0")
d = readxml("/usr/share/gir-1.0/$(GI.ns_id(ns)).gir")

## constants, enums, and flags, put in a "Constants" submodule

const_mod = Expr(:block)

const_exports = Expr(:export)

c = GI.all_const_exprs!(const_mod, const_exports, ns)
GI.append_const_docs!(const_mod.args, "gsk4", d, c)

push!(exprs, const_mod)

## export constants, enums, and flags code
GI.write_to_file(path,"gsk4_consts",toplevel)

## structs

toplevel, exprs, exports = GI.output_exprs()

# These are marked as "disguised" and what this means is not documentated AFAICT.
disguised = Symbol[]
struct_skiplist=vcat(disguised, Symbol[:ShaderArgsBuilder])

GI.struct_cache_expr!(exprs)
struct_skiplist,c = GI.all_struct_exprs!(exprs,exports,ns;excludelist=struct_skiplist,import_as_opaque=[:RoundedRect],output_cache_init=false)
GI.append_struc_docs!(exprs, "gsk4", d, c, ns)

## objects

c = GI.all_objects!(exprs,exports,ns,,output_cache_define=false,output_cache_init=false)
GI.append_object_docs!(exprs, "gsk4", d, c, ns)
GI.all_interfaces!(exprs,exports,ns)

push!(exprs,exports)

GI.write_to_file(path,"gsk4_structs",toplevel)

# struct methods

toplevel, exprs, exports = GI.output_exprs()

GI.all_struct_methods!(exprs,ns,struct_skiplist=struct_skiplist)

## object methods

# skips are to avoid method name collisions
GI.all_object_methods!(exprs,ns)

# skips are to avoid method name collisions
GI.all_interface_methods!(exprs,ns)

GI.write_to_file(path,"gsk4_methods",toplevel)

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

GI.write_to_file(path,"gsk4_functions",toplevel)
