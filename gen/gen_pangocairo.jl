using GI

ns = GINamespace(:PangoCairo,"1.0")
path="../src/gen"

struct_skiplist = GI.export_struct_exprs!(ns,path, "pangocairo", struct_skiplist, []; output_boxed_types_def = false, output_boxed_cache_init = false, output_object_cache_define = false, output_object_cache_init = false)

toplevel, exprs, exports = GI.output_exprs()

GI.all_interface_methods!(exprs,ns)

GI.write_to_file(path,"pangocairo_methods",toplevel)

## functions

toplevel, exprs, exports = GI.output_exprs()

skiplist=[:glyph_string_path,:layout_line_path,:show_glyph_item,:show_glyph_string,:show_layout_line]

GI.all_functions!(exprs,ns,skiplist=skiplist)

GI.write_to_file(path,"pangocairo_functions",toplevel)
