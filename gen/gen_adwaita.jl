using GI

ns = GINamespace(:Adw,"1")
path="../Adwaita/src/gen"

GI.export_consts!(ns, path, "adw"; export_constants = false)

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

skiplist=[:get_expression,:set_expression,:add_breakpoint,:get_current_breakpoint]

GI.export_methods!(ns, path, "adw"; struct_skiplist = struct_skiplist, object_method_skiplist = skiplist, object_skiplist = obj_skiplist, exclude_deprecated=false)

GI.export_functions!(ns, path, "adw"; skiplist=[:breakpoint_condition_parse])
