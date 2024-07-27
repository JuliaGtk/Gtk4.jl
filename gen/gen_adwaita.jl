using GI

toplevel, exprs, exports = GI.output_exprs()

ns = GINamespace(:Adw,"1")
path="../Adwaita/src/gen"

## constants, enums, and flags, put in a "Constants" submodule

const_mod = Expr(:block)

const_exports = Expr(:export)

GI.all_const_exprs!(const_mod, const_exports, ns)

push!(exprs, const_mod)

## export constants, enums, and flags code
GI.write_to_file(path,"adw_consts",toplevel)

## structs

toplevel, exprs, exports = GI.output_exprs()

struct_skiplist=[:BreakpointCondition]

first_list=[]
GI.struct_cache_expr!(exprs)
GI.struct_exprs!(exprs,exports,ns,first_list)

struct_skiplist=vcat(first_list,struct_skiplist)

struct_skiplist,c = GI.all_struct_exprs!(exprs,exports,ns;excludelist=struct_skiplist, constructor_skiplist=[:new_full], exclude_deprecated=false)

## objects

GI.all_interfaces!(exprs,exports,ns)
obj_skiplist=[:Breakpoint]
GI.all_objects!(exprs,exports,ns; skiplist=obj_skiplist, exclude_deprecated=false)

push!(exprs,exports)

GI.write_to_file(path,"adw_structs",toplevel)

## struct methods

toplevel, exprs, exports = GI.output_exprs()

skiplist=[]

GI.all_struct_methods!(exprs,ns,print_detailed=true,skiplist=skiplist,struct_skiplist=struct_skiplist)

## object methods

skiplist=[:get_expression,:set_expression,:add_breakpoint,:get_current_breakpoint]

# skips are to avoid method name collisions
GI.all_object_methods!(exprs,ns;skiplist=skiplist,object_skiplist=obj_skiplist, exclude_deprecated=false)

# skips are to avoid method name collisions
GI.all_interface_methods!(exprs,ns)

GI.write_to_file(path,"adw_methods",toplevel)

## functions

toplevel, exprs, exports = GI.output_exprs()

GI.all_functions!(exprs,ns;skiplist=[:breakpoint_condition_parse])

GI.write_to_file(path,"adw_functions",toplevel)
