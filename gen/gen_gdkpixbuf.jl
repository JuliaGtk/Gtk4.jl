using GI

toplevel, exprs, exports = GI.output_exprs()

ns = GINamespace(:GdkPixbuf,"2.0")
d = GI.read_gir(gdk_pixbuf_jll, ns)
path="../src/gen"

## constants, enums, and flags, put in a "Constants" submodule

const_mod = Expr(:block)

const_exports = Expr(:export)

c = GI.all_const_exprs!(const_mod, const_exports, ns, skiplist=[:PixbufFormatFlags])
GI.append_const_docs!(const_mod.args, "gdk-pixbuf", d, c)

push!(exprs, const_mod)

## export constants, enums, and flags code
GI.write_to_file(path,"gdkpixbuf_consts",toplevel)

## structs

toplevel, exprs, exports = GI.output_exprs()

disguised = GI.read_disguised(d)
struct_skiplist=vcat(disguised,[:PixbufModule])

first_list=[:PixbufModulePattern]

GI.struct_cache_expr!(exprs)
GI.struct_exprs!(exprs,exports,ns,first_list;excludelist=struct_skiplist)

struct_skiplist=vcat(first_list,struct_skiplist)

struct_skiplist,c = GI.all_struct_exprs!(exprs,exports,ns;excludelist=struct_skiplist)
GI.append_struc_docs!(exprs, "gdk-pixbuf", d, c, ns)

## objects

c = GI.all_objects!(exprs,exports,ns;constructor_skiplist=[:new_from_resource,:new_with_mime_type,:new_from_resource_at_scale])
GI.append_object_docs!(exprs, "gdk-pixbuf", d, c, ns)
GI.all_callbacks!(exprs, exports, ns)
push!(exprs,exports)

GI.write_to_file(path,"gdkpixbuf_structs",toplevel)

## struct methods

toplevel, exprs, exports = GI.output_exprs()

GI.all_struct_methods!(exprs,ns,struct_skiplist=struct_skiplist)

## object methods

skiplist=[:get_iter,:advance,:get_file_info_finish,:new_from_stream_async]

GI.all_object_methods!(exprs,ns;skiplist=skiplist)

GI.write_to_file(path,"gdkpixbuf_methods",toplevel)

## functions

toplevel, exprs, exports = GI.output_exprs()

GI.all_functions!(exprs,ns)

GI.write_to_file(path,"gdkpixbuf_functions",toplevel)
