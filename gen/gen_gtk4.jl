using GI

path="../src/gen"

ns = GINamespace(:Gtk,"4.0")
d = readxml("/usr/share/gir-1.0/$(GI.ns_id(ns)).gir")

GI.export_consts!(ns, path, "gtk4", [:CssParserError,:CssParserWarning]; doc_xml = d)

## structs

toplevel, exprs, exports = GI.output_exprs()

# These are marked as "disguised" and what this means is not documentated AFAICT.
disguised = Symbol[]
struct_skiplist=vcat(disguised, [:PageRange,:TreeRowReference])
constructor_skiplist=[:new_first]

GI.struct_cache_expr!(exprs)
struct_skiplist,c = GI.all_struct_exprs!(exprs,exports,ns;excludelist=struct_skiplist,constructor_skiplist=constructor_skiplist,import_as_opaque=[:BitsetIter,:BuildableParser],output_cache_init=false, exclude_deprecated=false)
GI.append_struc_docs!(exprs, "gtk4", d, c, ns)

## objects

object_skiplist=[:CClosureExpression,:ClosureExpression,:ParamSpecExpression,:PrintUnixDialog,:PageSetupUnixDialog]

GI.all_interfaces!(exprs,exports,ns;exclude_deprecated=false)
c = GI.all_objects!(exprs,exports,ns,exclude_deprecated=false,skiplist=object_skiplist,constructor_skiplist=[:new_from_resource,:new_with_mnemonic,:new_with_text,:new_with_entry,:new_with_model_and_entry,:new_for_resource,:new_from_icon_name],output_cache_define=false,output_cache_init=false)
GI.append_object_docs!(exprs, "gtk4", d, c, ns; skiplist=[:Builder])
GI.all_callbacks!(exprs, exports, ns)
GI.all_object_signals!(exprs,ns;skiplist=skiplist,object_skiplist=object_skiplist,exclude_deprecated=false)

push!(exprs,exports)

GI.write_to_file(path,"gtk4_structs",toplevel)

## struct methods

toplevel, exprs, exports = GI.output_exprs()

GI.all_struct_methods!(exprs,ns,struct_skiplist=vcat(struct_skiplist,[:Bitset,:BitsetIter,:BuildableParseContext,:CssSection,:TextIter]);print_detailed=true,exclude_deprecated=false)

## object methods

skiplist=[:create_closure,:activate_cell,:event,:start_editing,:filter_keypress,:append_node,:im_context_filter_keypress,:get_backlog,:get,:get_default,:get_for_display,:get_current_event_state,:get_axes]

object_skiplist=vcat(object_skiplist,[:CellRenderer,:MnemonicAction,:NeverTrigger,:NothingAction,:PrintJob,:PrintSettings,:RecentManager])

# skips are to avoid method name collisions
GI.all_object_methods!(exprs,ns;skiplist=skiplist,object_skiplist=object_skiplist,exclude_deprecated=false)

skiplist=[:start_editing,:install_properties]
# skips are to avoid method name collisions
GI.all_interface_methods!(exprs,ns;skiplist=skiplist,interface_skiplist=[:PrintOperationPreview],exclude_deprecated=false)

GI.write_to_file(path,"gtk4_methods",toplevel)

## functions

toplevel, exprs, exports = GI.output_exprs()

skiplist=[:editable_install_properties,:ordering_from_cmpfunc,:value_set_expression,:value_take_expression]

GI.all_functions!(exprs,ns,skiplist=skiplist,exclude_deprecated=false)

GI.write_to_file(path,"gtk4_functions",toplevel)
