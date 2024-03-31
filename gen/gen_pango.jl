using GI

ns = GINamespace(:Pango,"1.0")
path="../src/gen"

GI.export_consts!(ns, path, "pango"; export_constants = false)

## structs

toplevel, exprs, exports = GI.output_exprs()

first_list=[:Language,:Color,:AttrClass,:Rectangle,:FontDescription,:Attribute,:Analysis,:Item,:GlyphVisAttr,:GlyphGeometry,:GlyphInfo,:GlyphString,:GlyphItem]
GI.struct_cache_expr!(exprs)
GI.struct_exprs!(exprs,exports,ns,first_list)

struct_skiplist,c = GI.all_struct_exprs!(exprs,exports,ns;excludelist=first_list)

# we want the methods from first_list
struct_skiplist=Symbol[]

## objects

GI.all_objects!(exprs,exports,ns)
GI.all_interfaces!(exprs,exports,ns)
GI.all_callbacks!(exprs, exports, ns)
GI.all_object_signals!(exprs,ns)

push!(exprs,exports)

GI.write_to_file(path,"pango_structs",toplevel)

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

## functions

toplevel, exprs, exports = GI.output_exprs()

GI.all_functions!(exprs,ns)

GI.write_to_file(path,"pango_functions",toplevel)
