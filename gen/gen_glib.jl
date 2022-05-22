using GI

toplevel, exprs, exports = GI.output_exprs()

path="../src/gen"
mkpath(path)

ns = GINamespace(:GLib, "2.0")
ns2 = GINamespace(:GObject, "2.0")
ns3 = GINamespace(:Gio, "2.0")

# This exports constants, structs, functions, etc. from the glib library. Most
# of the functionality overlaps what can be done in Julia, but it is a
# good starting point for getting GI.jl working fully.

## constants, enums, and flags, put in a "Constants" submodule

const_mod = Expr(:block)

const_exports = Expr(:export)

GI.all_const_exprs!(const_mod, const_exports, ns; incl_typeinit=false)
GI.all_const_exprs!(const_mod, const_exports, ns2, skiplist=[:ConnectFlags,:ParamFlags,:SignalFlags,:SignalMatchType,:TypeFlags,:TypeFundamentalFlags])
GI.all_const_exprs!(const_mod, const_exports, ns3, skiplist=[:TlsProtocolVersion])

push!(const_mod.args,const_exports)

push!(exprs, const_mod)

## export constants, enums, and flags code
GI.write_to_file(path,"glib_consts",toplevel)

## structs

toplevel, exprs, exports = GI.output_exprs()

# These are marked as "disguised" and what this means is not documentated AFAICT.
disguised = [:AsyncQueue, :BookmarkFile, :Data, :Dir, :Hmac, :Iconv,
            :OptionContext, :PatternSpec, :Rand, :Sequence, :SequenceIter,
            :SourcePrivate, :StatBuf, :StringChunk, :StrvBuilder, :TestCase,
            :TestSuite, :Timer, :TreeNode]

# These are handled specially by GLib.jl so are not auto-exported.
special = [:List,:SList,:Error,:Variant,:HashTable,:Array,:ByteArray,:PtrArray,:SourceFuncs]
# Treat these as opaque even though there are fields
import_as_opaque = [:Date,:Source]

# These include callbacks or are otherwise currently problematic
struct_skiplist=vcat(disguised, special, [:Cond,:HashTableIter,:Hook,
    :HookList,:IOChannel,:IOFuncs,
    :MarkupParser,:MemVTable,:Node,:Once,:OptionGroup,:PollFD,:Private,:Queue,:RWLock,
    :RecMutex,:Scanner,
    :TestLogBuffer,:TestLogMsg,:Thread,:ThreadPool,:Tree,:UriParamsIter])

GI.all_struct_exprs!(exprs,exports,ns;excludelist=struct_skiplist,import_as_opaque=import_as_opaque)

push!(exprs,exports)

GI.write_to_file(path,"glib_structs",toplevel)

## struct methods

toplevel, exprs, exports = GI.output_exprs()

name_issues=[:end]

skiplist=vcat(name_issues,[
:add_poll,:remove_poll,:check,:query,:find_source_by_funcs_user_data,:get_region,:invoke_full,:new_from_data,:find_source_by_id,:find_source_by_user_data])

filter!(x->x≠:Variant,struct_skiplist)
filter!(x->x≠:ByteArray,struct_skiplist)
filter!(x->x≠:Error,struct_skiplist)

struct_skiplist=vcat(struct_skiplist,[:Error,:MarkupParseContext,:Source])

symbols_handled=GI.all_struct_methods!(exprs,ns;print_detailed=true,skiplist=skiplist,struct_skiplist=struct_skiplist)

GI.write_to_file(path,"glib_methods",toplevel)

## functions

toplevel, exprs, exports = GI.output_exprs()

# many of these are skipped because they involve callbacks
skiplist=[:convert,:atomic_rc_box_release_full,:child_watch_add,:datalist_foreach,:dataset_foreach,:io_add_watch,:io_create_watch,:log_set_handler,:log_set_writer_func,:rc_box_release_full,:spawn_async,:spawn_async_with_fds,:spawn_async_with_pipes,:spawn_async_with_pipes_and_fds,:spawn_sync,:test_add_data_func,:test_add_data_func_full,:test_add_func,:test_queue_destroy,:thread_self, :unix_fd_add_full,:unix_signal_add, :datalist_get_data, :datalist_get_flags, :datalist_id_get_data, :datalist_set_flags, :datalist_unset_flags,:hook_destroy,:hook_destroy_link,:hook_free,:hook_insert_before, :hook_prepend,:hook_unref,:poll, :sequence_get,:sequence_move,:sequence_move_range,:sequence_remove,:sequence_remove_range,:sequence_set,:sequence_swap,:shell_parse_argv,:source_remove_by_funcs_user_data,:test_run_suite, :assertion_message_error,:uri_parse_params, :pattern_match,:pattern_match_string,:log_structured_array,:log_writer_default,:log_writer_format_fields,:log_writer_journald,:log_writer_standard_streams,:parse_debug_string,:child_watch_source_new,:date_strftime,:idle_source_new,:main_current_source,:timeout_source_new,:timeout_source_new_seconds,:unix_fd_source_new,:unix_signal_source_new]

GI.all_functions!(exprs,ns,skiplist=skiplist,symbol_skiplist=symbols_handled)

GI.write_to_file(path,"glib_functions",toplevel)
