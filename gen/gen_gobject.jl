using GI

toplevel, exprs, exports = GI.output_exprs()

path="../src/gen"

ns = GINamespace(:GObject,"2.0")

## structs

# These are marked as "disguised" and what this means is not documentated AFAICT.
disguised = [:ParamSpecPool]
# These are handled specially by GLib.jl so are not auto-exported.
special = [:Value]
import_as_opaque = [:ObjectClass]
struct_skiplist=vcat(disguised, special, [:CClosure,:Closure,:ClosureNotifyData,
:InterfaceInfo,:ObjectConstructParam,:ParamSpecTypeInfo,:TypeInfo,:TypeInstance,
:TypeInterface,:TypeValueTable,:WeakRef])

first_list=[:EnumValue,:TypeClass,:FlagsValue]
GI.struct_exprs!(exprs,exports,ns,first_list)

struct_skiplist=vcat(struct_skiplist,first_list)

struct_skiplist = GI.all_struct_exprs!(exprs,exports,ns;excludelist=struct_skiplist,import_as_opaque=import_as_opaque,output_cache_init=false)

## objects and interfaces

GI.all_objects!(exprs,exports,ns;handled=[:Object])
push!(exprs,:(gtype_wrapper_cache[:GObject] = GObjectLeaf))
GI.all_interfaces!(exprs,exports,ns)

push!(exprs,exports)

GI.write_to_file(path,"gobject_structs",toplevel)

## struct methods

toplevel, exprs, exports = GI.output_exprs()

structs=GI.get_structs(ns)

skiplist=[:init_from_instance,:get_private]

filter!(x->x≠:Value,struct_skiplist)

symbols_handled=GI.all_struct_methods!(exprs,ns;print_detailed=true,skiplist=skiplist,struct_skiplist=struct_skiplist)

## object methods

skiplist=[
:bind_property_full,  # "binding friendly" GI version uses GClosure
:watch_closure,:add_interface,:register_enum,:register_flags,:register_type,
:getv]

GI.all_object_methods!(exprs,ns;skiplist=skiplist)

GI.write_to_file(path,"gobject_methods",toplevel)

## functions

toplevel, exprs, exports = GI.output_exprs()

# functions that are handled in the library already
handled_list=[:type_from_name,:type_is_a,:type_name,:type_parent,:type_test_flags]

skiplist=vcat(handled_list,[:enum_complete_type_info,:enum_register_static,:flags_complete_type_info,
:flags_register_static,:param_type_register_static,:signal_accumulator_first_wins,
:signal_accumulator_true_handled,:signal_connect_closure,:signal_connect_closure_by_id,
:signal_handler_find,:signal_handlers_block_matched,:signal_handlers_disconnect_matched,
:signal_handlers_unblock_matched,:signal_override_class_closure,:signal_query,
:source_set_closure,:source_set_dummy_callback,:type_add_interface_static,
:type_check_instance,:type_check_instance_is_a,:type_check_instance_is_fundamentally_a,
:type_default_interface_unref,:type_free_instance,
:type_name_from_instance,:type_register_fundamental,:type_register_static,
:signal_set_va_marshaller,:signal_emitv])

GI.all_functions!(exprs,ns,skiplist=skiplist,symbol_skiplist=symbols_handled)

GI.write_to_file(path,"gobject_functions",toplevel)
