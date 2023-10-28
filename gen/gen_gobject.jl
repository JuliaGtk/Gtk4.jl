using GI

printstyled("Generating code for GObject\n";bold=true)

toplevel, exprs, exports = GI.output_exprs()

path="../src/gen"

ns = GINamespace(:GObject,"2.0")
d = GI.read_gir(gobject_introspection_jll, ns)

## structs

disguised = GI.read_disguised(d)
# These are handled specially by GLib.jl so are not auto-exported.
special = [:Value]
import_as_opaque = [:ObjectClass]
struct_skiplist=vcat(disguised, special, [:CClosure,:Closure,:ClosureNotifyData,
:InterfaceInfo,:ObjectConstructParam,:ParamSpecTypeInfo,:TypeInstance,
:TypeInterface,:WeakRef])

# these struct types are members in other structs, so we export them first
first_list=[:EnumValue,:TypeClass,:FlagsValue,:TypeValueTable]
GI.struct_exprs!(exprs,exports,ns,first_list)

struct_skiplist=vcat(struct_skiplist,first_list)

struct_skiplist, c = GI.all_struct_exprs!(exprs,exports,ns;excludelist=struct_skiplist,import_as_opaque=import_as_opaque,output_cache_init=false)
GI.append_struc_docs!(exprs, "gobject", d, c, ns)

## objects and interfaces

c = GI.all_objects!(exprs,exports,ns;handled=[:Object],skiplist=[:SignalGroup])
GI.append_object_docs!(exprs, "gobject", d, c, ns)
push!(exprs,:(gtype_wrapper_cache[:GObject] = GObjectLeaf))
GI.all_interfaces!(exprs,exports,ns)
GI.all_callbacks!(exprs, exports, ns)
GI.all_object_signals!(exprs, ns;skiplist=skiplist,object_skiplist=[:BindingGroup,:SignalGroup,:Object])

push!(exprs,exports)

GI.write_to_file(path,"gobject_structs",toplevel)

## struct methods

toplevel, exprs, exports = GI.output_exprs()

structs=GI.get_structs(ns)

skiplist=[:init_from_instance,:get_private,:get_param,:set_param]

filter!(x->x≠:Value,struct_skiplist)

symbols_handled=GI.all_struct_methods!(exprs,ns;skiplist=skiplist,struct_skiplist=struct_skiplist)

## object methods

skiplist=[
:bind_property_full,  # "binding friendly" GI version uses GClosure
:watch_closure,:add_interface,:register_enum,:register_flags,:register_type,
:getv,:notify_by_pspec,:interface_find_property,:interface_install_property,:interface_list_properties]

GI.all_object_methods!(exprs,ns;skiplist=skiplist,object_skiplist=[:BindingGroup,:SignalGroup])

GI.write_to_file(path,"gobject_methods",toplevel)

## functions

toplevel, exprs, exports = GI.output_exprs()

# functions that are handled in the package already
handled_list=[:type_from_name,:type_is_a,:type_name,:type_parent,:type_test_flags]

skiplist=vcat(handled_list,[:enum_complete_type_info,:enum_register_static,:flags_complete_type_info,
:flags_register_static,:param_type_register_static,:signal_accumulator_first_wins,
:signal_accumulator_true_handled,:signal_connect_closure,:signal_connect_closure_by_id,
:signal_handler_find,:signal_handlers_block_matched,:signal_handlers_disconnect_matched,
:signal_handlers_unblock_matched,:signal_override_class_closure,
:source_set_closure,:source_set_dummy_callback,:type_add_interface_static,
:type_check_instance,:type_check_instance_is_a,:type_check_instance_is_fundamentally_a,
:type_default_interface_unref,:type_free_instance,
:type_name_from_instance,:type_register_fundamental,
:signal_set_va_marshaller,:signal_emitv,:param_value_convert,:param_value_defaults,:param_value_set_default,:param_value_validate,:param_values_cmp])

GI.all_functions!(exprs,ns,skiplist=skiplist,symbol_skiplist=symbols_handled)

GI.write_to_file(path,"gobject_functions",toplevel)
