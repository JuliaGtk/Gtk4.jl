using GI
GI.prepend_search_path("/usr/lib64/girepository-1.0")

ns = GINamespace(:cairo,"1.0")
path="../src/gen"

GI.export_consts!(ns, path, "cairo"; export_constants = false)
struct_skiplist = []
struct_skiplist = GI.export_struct_exprs!(ns,path, "cairo", struct_skiplist, []; output_object_cache_init = false, output_object_cache_define = false)
GI.export_functions!(ns,path,"cairo")
