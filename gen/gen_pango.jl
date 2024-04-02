using GI

ns = GINamespace(:Pango,"1.0")
path="../src/gen"

GI.export_consts!(ns, path, "pango"; export_constants = false)

## structs

toplevel, exprs, exports = GI.output_exprs()

first_list=[:Language,:Color,:AttrClass,:Rectangle,:FontDescription,:Attribute,:Analysis,:Item,:GlyphVisAttr,:GlyphGeometry,:GlyphInfo,:GlyphString,:GlyphItem]

struct_skiplist = []

GI.export_struct_exprs!(ns,path, "pango", [], []; first_list = first_list)

## struct methods

toplevel, exprs, exports = GI.output_exprs()

skiplist=[:filter,:get_tabs]

GI.all_struct_methods!(exprs,ns,print_detailed=true,skiplist=skiplist,struct_skiplist=struct_skiplist)

## object methods

skiplist=[:get_features]

# skips are to avoid method name collisions
GI.all_object_methods!(exprs,ns;skiplist=skiplist)

# skips are to avoid method name collisions
GI.all_interface_methods!(exprs,ns)

GI.write_to_file(path,"pango_methods",toplevel)

GI.export_functions!(ns,path,"pango")

