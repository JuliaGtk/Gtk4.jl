using GI

ns = GINamespace(:Pango,"1.0")
path="../src/gen"

GI.export_consts!(ns, path, "pango"; export_constants = false)

## structs

toplevel, exprs, exports = GI.output_exprs()

first_list=[:Language,:Color,:AttrClass,:Rectangle,:FontDescription,:Attribute,:Analysis,:Item,:GlyphVisAttr,:GlyphGeometry,:GlyphInfo,:GlyphString,:GlyphItem]

struct_skiplist = []

GI.export_struct_exprs!(ns,path, "pango", [], []; first_list = first_list)

struct_method_skiplist=[:filter,:get_tabs]

# skips are to avoid method name collisions
object_method_skiplist=[:get_features]

GI.export_methods!(ns,path,"pango"; object_method_skiplist = object_method_skiplist, struct_skiplist = struct_skiplist, struct_method_skiplist = struct_method_skiplist)
GI.export_functions!(ns,path,"pango")

