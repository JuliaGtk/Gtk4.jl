using GI

toplevel, exprs, exports = GI.output_exprs()

ns = GINamespace(:GdkPixbuf,"2.0")
path="../src/gen"

## constants, enums, and flags, put in a "Constants" submodule

const_mod = Expr(:block)

const_exports = Expr(:export)

GI.all_const_exprs!(const_mod, const_exports, ns, skiplist=[:PixbufFormatFlags])

push!(exprs, const_mod)

## export constants, enums, and flags code
GI.write_to_file(path,"gdkpixbuf_consts",toplevel)

## structs

toplevel, exprs, exports = GI.output_exprs()

struct_skiplist=[:PixbufModule]

first_list=[:PixbufModulePattern]

GI.struct_cache_expr!(exprs)
GI.struct_exprs!(exprs,exports,ns,first_list;excludelist=struct_skiplist)

struct_skiplist=vcat(first_list,struct_skiplist)

struct_skiplist = GI.all_struct_exprs!(exprs,exports,ns;excludelist=struct_skiplist)

## objects

GI.all_objects!(exprs,exports,ns)
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
