using GI

ns = GINamespace(:cairo,"1.0")
path="../src/gen"

GI.export_consts!(ns, path, "cairo"; doc_xml = d, export_constants = false)
struct_skiplist = GI.export_struct_exprs!(ns,path, "cairo", struct_skiplist, [])

## functions

toplevel, exprs, exports = GI.output_exprs()

skiplist=Symbol[]

GI.all_functions!(exprs,ns,skiplist=skiplist)

GI.write_to_file(path,"cairo_functions",toplevel)
