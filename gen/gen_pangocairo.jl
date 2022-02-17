using GI

toplevel, exprs, exports = GI.output_exprs()

ns = GINamespace(:PangoCairo,"1.0")
path="../src/gen"

## functions

toplevel, exprs, exports = GI.output_exprs()

skiplist=[:glyph_string_path,:layout_line_path,:show_glyph_item,:show_glyph_string,:show_layout_line]

GI.all_functions!(exprs,ns,skiplist=skiplist)

GI.write_to_file(path,"pangocairo_functions",toplevel)
