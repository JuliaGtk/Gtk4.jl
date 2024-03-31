using GI

path="../src/gen"

ns = GINamespace(:Gsk,"4.0")
d = readxml("/usr/share/gir-1.0/$(GI.ns_id(ns)).gir")

GI.export_consts!(ns, path, "gsk4"; doc_xml = d, export_constants = false)

## structs

toplevel, exprs, exports = GI.output_exprs()

# These are marked as "disguised" and what this means is not documentated AFAICT.
disguised = Symbol[]
struct_skiplist=vcat(disguised, Symbol[:ShaderArgsBuilder])

GI.struct_cache_expr!(exprs)
struct_skiplist,c = GI.all_struct_exprs!(exprs,exports,ns;excludelist=struct_skiplist,import_as_opaque=[:RoundedRect],output_cache_init=false)
GI.append_struc_docs!(exprs, "gsk4", d, c, ns)

## objects

c = GI.all_objects!(exprs,exports,ns,output_cache_define=false,output_cache_init=false)
GI.append_object_docs!(exprs, "gsk4", d, c, ns)
GI.all_interfaces!(exprs,exports,ns)
GI.all_object_signals!(exprs,ns)

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

## functions

toplevel, exprs, exports = GI.output_exprs()

GI.all_functions!(exprs,ns)

GI.write_to_file(path,"gsk4_functions",toplevel)
