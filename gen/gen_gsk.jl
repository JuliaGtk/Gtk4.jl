using GI

path="../src/gen"

ns = GINamespace(:Gsk,"4.0")
d = readxml("/usr/share/gir-1.0/$(GI.ns_id(ns)).gir")

GI.export_consts!(ns, path, "gsk4"; doc_xml = d, export_constants = false)

# These are marked as "disguised" and what this means is not documentated AFAICT.
disguised = Symbol[]
struct_skiplist=vcat(disguised, Symbol[:ShaderArgsBuilder])

GI.export_struct_exprs!(ns,path, "gsk4", struct_skiplist, [:RoundedRect]; doc_xml = d, output_boxed_cache_init = false, output_object_cache_define = false, output_object_cache_init = false, output_callbacks = false)

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
