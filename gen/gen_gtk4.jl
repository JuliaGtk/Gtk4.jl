using GI

toplevel, exprs, exports = GI.output_exprs()

path="../src/gen"

ns = GINamespace(:Gtk,"4.0")

## constants, enums, and flags, put in a "Constants" submodule

const_mod = Expr(:block)

push!(const_mod.args,:(using CEnum, BitFlags))

const_exports = Expr(:export)

GI.all_const_exprs!(const_mod, const_exports, ns)
push!(const_mod.args, const_exports)

push!(exprs, Expr(:toplevel,Expr(:module, true, :Constants, const_mod)))

## export constants, enums, and flags code
GI.write_to_file(path,"gtk4_consts",toplevel)

## structs

 toplevel, exprs, exports = GI.output_exprs()

# These are marked as "disguised" and what this means is not documentated AFAICT.
disguised = []
struct_skiplist=vcat(disguised, [:PageRange])

GI.struct_cache_expr!(exprs)
struct_skiplist = GI.all_struct_exprs!(exprs,exports,ns;excludelist=struct_skiplist,import_as_opaque=[:BitsetIter,:BuildableParser])

## objects

object_skiplist=[:CClosureExpression,:ClosureExpression,:ConstantExpression,:Expression,:ObjectExpression,:PropertyExpression,:ParamSpecExpression,:PrintUnixDialog,:PageSetupUnixDialog]

GI.all_objects!(exprs,exports,ns,skiplist=object_skiplist)
GI.all_interfaces!(exprs,exports,ns)

push!(exprs,exports)

GI.write_to_file(path,"gtk4_structs",toplevel)

## struct methods

toplevel, exprs, exports = GI.output_exprs()

skiplist=[]

GI.all_struct_methods!(exprs,ns,skiplist=skiplist,struct_skiplist=vcat(struct_skiplist,[:Bitset,:BitsetIter,:BuildableParseContext,:CssSection,:TextIter]);print_detailed=true)

## object methods

skiplist=[:create_closure,:activate_cell,:event,:start_editing,:filter_keypress,:trigger,:append_node,:im_context_filter_keypress,:get_backlog,:append_border,:append_inset_shadow,:append_outset_shadow,:push_rounded_clip]

object_skiplist=vcat(object_skiplist,[:BoolFilter,:CellRenderer,:DropDown,:IconTheme,:MnemonicAction,:NeverTrigger,:NothingAction,:NumericSorter,:PrintJob,:PrintSettings,:RecentManager,:StringFilter,:StringSorter,:ShortcutAction,:ShortcutTrigger])

# skips are to avoid method name collisions
GI.all_object_methods!(exprs,ns;skiplist=skiplist,object_skiplist=object_skiplist)

skiplist=[:start_editing,:install_properties]
# skips are to avoid method name collisions
GI.all_interface_methods!(exprs,ns;skiplist=skiplist,interface_skiplist=[:PrintOperationPreview])

GI.write_to_file(path,"gtk4_methods",toplevel)

## functions

toplevel, exprs, exports = GI.output_exprs()

skiplist=[]

GI.all_functions!(exprs,ns,skiplist=skiplist)

GI.write_to_file(path,"gtk4_functions",toplevel)
