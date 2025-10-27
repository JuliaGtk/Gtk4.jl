using GI, EzXML
GI.prepend_search_path("/usr/lib64/girepository-1.0")

ns = GINamespace(:PangoCairo,"1.0")
path="../src/gen"

struct_skiplist = GI.export_struct_exprs!(ns,path, "pangocairo", [], []; output_boxed_types_def = false, output_boxed_cache_init = false, output_object_cache_define = false, output_object_cache_init = false)

GI.export_methods!(ns,path,"pangocairo")

skiplist=[:glyph_string_path,:layout_line_path,:show_glyph_item,:show_glyph_string,:show_layout_line]
GI.export_functions!(ns,path,"pangocairo"; skiplist=skiplist)

