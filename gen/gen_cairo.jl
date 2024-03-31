using GI

ns = GINamespace(:cairo,"1.0")
path="../src/gen"

GI.export_consts!(ns, path, "cairo"; doc_xml = d, export_constants = false)

## structs

toplevel, exprs, exports = GI.output_exprs()

struct_skiplist=Symbol[]
GI.struct_cache_expr!(exprs)
struct_skiplist = GI.all_struct_exprs!(exprs,exports,ns;excludelist=struct_skiplist)
push!(exprs,exports)

GI.write_to_file(path,"cairo_structs",toplevel)

## functions

toplevel, exprs, exports = GI.output_exprs()

skiplist=Symbol[]

GI.all_functions!(exprs,ns,skiplist=skiplist)

GI.write_to_file(path,"cairo_functions",toplevel)
