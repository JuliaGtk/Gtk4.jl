using GI

toplevel, exprs, exports = GI.output_exprs()

ns = GINamespace(:cairo,"1.0")
path="../src/gen"

## constants, enums, and flags, put in a "Constants" submodule

const_mod = Expr(:block)

push!(const_mod.args,:(using CEnum, BitFlags))

const_exports = Expr(:export)

GI.all_const_exprs!(const_mod, const_exports, ns)

push!(exprs, Expr(:toplevel,Expr(:module, true, :Constants, const_mod)))

## export constants, enums, and flags code
GI.write_to_file(path,"cairo_consts",toplevel)

## structs

toplevel, exprs, exports = GI.output_exprs()

struct_skiplist=[]
GI.struct_cache_expr!(exprs)
struct_skiplist = GI.all_struct_exprs!(exprs,exports,ns;excludelist=struct_skiplist)
push!(exprs,exports)

GI.write_to_file(path,"cairo_structs",toplevel)

## functions

toplevel, exprs, exports = GI.output_exprs()

skiplist=[]

GI.all_functions!(exprs,ns,skiplist=skiplist)

GI.write_to_file(path,"cairo_functions",toplevel)
