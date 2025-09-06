using GI, EzXML

printstyled("Generating constants for GLib, GObject, and Gio\n";bold=true)

toplevel, exprs, exports = GI.output_exprs()

path="../src/gen"
mkpath(path)

ns = GINamespace(:GLib, "2.0")
ns2 = GINamespace(:GObject, "2.0")
ns3 = GINamespace(:Gio, "2.0")

# GI.get_shlibs() gets confused sometimes and for some reason this helps...
println(GI.get_shlibs(ns3))

# This exports constants, structs, functions, etc. from the glib library

# Constants for GLib, GObject, and Gio are grouped together. Structs and methods
# are kept separate because we need to interweave the automatically generated
# code with hand-written code. See "gen_gobject.jl" and "gen_gio.jl".

const_mod = Expr(:block)

const_exports = Expr(:export)

# Out of principle, let's skip some mathematical constants that are stored to only 6 decimals
const_skip = [:E,:LN2,:LN10,:LOG_2_BASE_10,:PI,:PI_2,:PI_4,:SQRT2]

c = GI.all_const_exprs!(const_mod, const_exports, ns, skiplist=const_skip; incl_typeinit=false)
dglib = readxml("/usr/share/gir-1.0/$(GI.ns_id(ns)).gir")
GI.append_const_docs!(const_mod.args, "glib", dglib, c)
c = GI.all_const_exprs!(const_mod, const_exports, ns2, skiplist=[:IOCondition])
d = readxml("/usr/share/gir-1.0/$(GI.ns_id(ns2)).gir")
GI.append_const_docs!(const_mod.args, "gobject", d, c)
c = GI.all_const_exprs!(const_mod, const_exports, ns3, skiplist=[:TlsProtocolVersion])
d = readxml("/usr/share/gir-1.0/$(GI.ns_id(ns3)).gir")
GI.append_const_docs!(const_mod.args, "gio", d, c)
push!(const_mod.args,const_exports)

push!(exprs, const_mod)

## export constants, enums, and flags code
GI.write_consts_to_file(path,"glib_consts",toplevel)

printstyled("Generating code for GLib\n";bold=true)

## structs

# Some structs are marked as "disguised" in the XML and what this means is not clear to me,
# but they look like they are of no use to us.
disguised = GI.read_disguised(dglib)

# These are handled specially by GLib.jl so are not auto-exported.
special = [:List,:SList,:Error,:Variant,:HashTable,:Array,:ByteArray,:PtrArray,:SourceFuncs]
# Treat these as opaque even though there are fields
import_as_opaque = [:Date,:Source]

# These include callbacks or are otherwise currently problematic
struct_skiplist=vcat(disguised, special, [:Cond,:HashTableIter,:Hook,
    :HookList,:IOChannel,:IOFuncs,
    :MarkupParser,:MemVTable,:Node,:Once,:OptionGroup,:PathBuf,:PollFD,:Private,:Queue,:RWLock,
    :RecMutex,:Scanner,
    :TestLogBuffer,:TestLogMsg,:Thread,:ThreadPool,:Tree,:UriParamsIter])

callback_skiplist=[:LogWriterFunc]
constructor_skiplist=[:new,:new_take,:new_from_unix_utc,:new_now_utc,:new_utc,:new_maybe,:new_from_unix_local_usec,:new_from_unix_utc_usec]

GI.export_struct_exprs!(ns,path, "glib", struct_skiplist, import_as_opaque; doc_xml = dglib, constructor_skiplist = constructor_skiplist, output_object_cache_init = false, output_object_cache_define = false, output_boxed_types_def = false, callback_skiplist)

## struct methods

toplevel, exprs, exports = GI.output_exprs()

name_issues=[:end]

skiplist=vcat(name_issues,[
:get_application_info,:add_poll,:remove_poll,:check,:query,:find_source_by_funcs_user_data,:get_region,:invoke_full,:new_from_data,:find_source_by_id,:find_source_by_user_data])

filter!(x->x≠:Variant,struct_skiplist)
filter!(x->x≠:ByteArray,struct_skiplist)
filter!(x->x≠:Error,struct_skiplist)

struct_skiplist=vcat(struct_skiplist,[:Error,:MarkupParseContext,:Source])

# On Linux, which is the only platform where we generate code, glib symbols are present in both libgobject and libglib, and GI finds libgobject
# first. The override points GI at libglib, which is necessary on Windows because there, libglib's symbols aren't present in libgobject.
# This can be removed if we get GI working on all platforms.
symbols_handled=GI.all_struct_methods!(exprs,ns;print_detailed=false,skiplist=skiplist,struct_skiplist=struct_skiplist, liboverride=:libglib)

GI.write_to_file(path,"glib_methods",toplevel)

## functions

toplevel, exprs, exports = GI.output_exprs()

# many of these are skipped because they involve callbacks
skiplist=[:convert,:atomic_rc_box_release_full,:child_watch_add,:datalist_foreach,:dataset_foreach,
          :io_add_watch,:io_create_watch,:log_set_handler,:log_set_writer_func,:rc_box_release_full,
          :spawn_async,:spawn_async_with_fds,:spawn_async_with_pipes,:spawn_async_with_pipes_and_fds,
          :spawn_sync,:test_add_data_func,:test_add_data_func_full,:test_add_func,:test_queue_destroy,
          :thread_self, :unix_fd_add_full,:unix_signal_add, :datalist_get_data, :datalist_get_flags,
          :datalist_id_get_data, :datalist_set_flags, :datalist_unset_flags,:hook_destroy,
          :hook_destroy_link,:hook_free,:hook_insert_before, :hook_prepend,:hook_unref,:poll,
          :sequence_get,:sequence_move,:sequence_move_range,:sequence_remove,:sequence_remove_range,
          :sequence_set,:sequence_swap,:shell_parse_argv,:source_remove_by_funcs_user_data,
          :test_run_suite,:assertion_message_error,:uri_parse_params, :pattern_match,
          :pattern_match_string,:log_structured_array,:log_writer_default,:log_writer_format_fields,
          :log_writer_journald,:log_writer_standard_streams,:parse_debug_string,:lstat,:stat,
          :child_watch_source_new,:date_strftime,:idle_source_new,:main_current_source,
          :timeout_source_new,:timeout_source_new_seconds,:unix_fd_source_new,:async_queue_new,
          :unix_signal_source_new,:datalist_id_remove_multiple,:base64_encode_close,
          :base64_encode_step,:sequence_insert_before,:sequence_range_get_midpoint,
          :list_push_allocator,:node_push_allocator,:slist_push_allocator,:sequence_foreach_range,:sequence_sort_changed,:sequence_sort_changed_iter]

GI.all_functions!(exprs,ns,skiplist=skiplist,symbol_skiplist=symbols_handled, liboverride=:libglib)

GI.write_to_file(path,"glib_functions",toplevel)
