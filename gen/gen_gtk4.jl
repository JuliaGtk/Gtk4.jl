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

GI.export_struct_exprs!(ns,path, "gtk4", struct_skiplist, [:BitsetIter,:BuildableParser]; doc_xml = d, object_skiplist = object_skiplist, constructor_skiplist = constructor_skiplist, output_boxed_cache_init = false, output_boxed_types_def = false, output_object_cache_define = false, output_object_cache_init = false, object_constructor_skiplist = obj_constructor_skiplist, doc_skiplist = [:Builder], exclude_deprecated = false)

## object methods
skiplist=[:create_closure,:activate_cell,:event,:start_editing,:filter_keypress,:append_node,:im_context_filter_keypress,:get_backlog,:get,:get_default,:get_for_display,:get_current_event_state,:get_axes]

object_skiplist=vcat(object_skiplist,[:CellRenderer,:MnemonicAction,:NeverTrigger,:NothingAction,:PrintJob,:PrintSettings,:RecentManager])

GI.export_methods!(ns,path,"gtk4"; exclude_deprecated = false, object_method_skiplist = skiplist, object_skiplist = object_skiplist, interface_method_skiplist = [:start_editing, :install_properties], interface_skiplist = [:PrintOperationPreview], struct_skiplist = vcat(struct_skiplist,[:Bitset,:BitsetIter,:BuildableParseContext,:CssSection,:TextIter]))

skiplist=[:editable_install_properties,:ordering_from_cmpfunc,:value_set_expression,:value_take_expression]

GI.export_functions!(ns,path,"gtk4"; skiplist = skiplist, exclude_deprecated=false)
