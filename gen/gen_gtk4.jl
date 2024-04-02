using GI

path="../src/gen"

ns = GINamespace(:Gtk,"4.0")
d = readxml("/usr/share/gir-1.0/$(GI.ns_id(ns)).gir")

GI.export_consts!(ns, path, "gtk4", [:CssParserError,:CssParserWarning]; doc_xml = d)

disguised = Symbol[]
struct_skiplist=vcat(disguised, [:PageRange,:TreeRowReference])
constructor_skiplist=[:new_first]

object_skiplist=[:CClosureExpression,:ClosureExpression,:ParamSpecExpression,:PrintUnixDialog,:PageSetupUnixDialog]
obj_constructor_skiplist=[:new_from_resource,:new_with_mnemonic,:new_with_text,:new_with_entry,:new_with_model_and_entry,:new_for_resource,:new_from_icon_name]

GI.export_struct_exprs!(ns,path, "gtk4", struct_skiplist, [:BitsetIter,:BuildableParser]; doc_xml = d, object_skiplist = object_skiplist, constructor_skiplist = constructor_skiplist, output_boxed_cache_init = false, output_object_cache_define = false, output_object_cache_init = false, object_constructor_skiplist = obj_constructor_skiplist, doc_skiplist = [:Builder], exclude_deprecated = false)

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

skiplist=[:editable_install_properties,:ordering_from_cmpfunc,:value_set_expression,:value_take_expression]

GI.export_functions!(ns,path,"gtk4"; skiplist = skiplist, exclude_deprecated=false)
