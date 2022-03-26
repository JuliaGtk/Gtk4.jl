# id = VERSION >= v"0.4-"get, :event, Nothing, (ArgsT...)) do ptr, evt_args..., closure
#    stuff
# end
function signal_connect(@nospecialize(cb::Function), w::GObject, sig::AbstractStringLike,
        ::Type{RT}, param_types::Tuple, after::Bool = false, user_data::CT = w) where {CT, RT}
    signal_connect_generic(cb, w, sig, RT, param_types, after, user_data)
end

function signal_connect_generic(@nospecialize(cb::Function), w::GObject, sig::AbstractStringLike,
        ::Type{RT}, param_types::Tuple, after::Bool = false, user_data::CT = w) where {CT, RT}  #TODO: assert that length(param_types) is correct
    callback = cfunction_(cb, RT, tuple(Ptr{GObject}, param_types..., Ref{CT}))
    ref, deref = gc_ref_closure(user_data)
    return ccall((:g_signal_connect_data, libgobject), Culong,
                 (Ptr{GObject}, Ptr{UInt8}, Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}, GEnum),
                 w,
                 bytestring(sig),
                 callback,
                 ref,
                 deref,
                 after * GConnectFlags.AFTER)
end

# id = signal_connect(widget, :event) do obj, evt_args...
#    stuff
# end
function signal_connect(@nospecialize(cb::Function), w::GObject, sig::AbstractStringLike, after::Bool = false)
    _signal_connect(cb, w, sig, after, false, nothing, nothing)
end
function _signal_connect(@nospecialize(cb::Function), w::GObject, sig::AbstractStringLike, after::Bool, gtk_call_conv::Bool, param_types, user_data)
    @assert sizeof_gclosure > 0
    closuref = ccall((:g_closure_new_object, libgobject), Ptr{Nothing}, (Cuint, Ptr{GObject}), sizeof_gclosure::Int + GLib.WORD_SIZE * 2, w)
    closure_env = convert(Ptr{Ptr{Nothing}}, closuref + sizeof_gclosure)
    if gtk_call_conv
        env = Any[param_types, user_data]
        ref_env, deref_env = gc_ref_closure(env)
        unsafe_store!(closure_env, ref_env, 2)
        ccall((:g_closure_add_invalidate_notifier, libgobject), Nothing,
            (Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}), closuref, ref_env, deref_env)
    else
        unsafe_store!(convert(Ptr{Int}, closure_env), 0, 2)
    end
    ref_cb, deref_cb = invoke(gc_ref_closure, Tuple{Function}, cb)
    unsafe_store!(closure_env, ref_cb, 1)
    ccall((:g_closure_add_invalidate_notifier, libgobject), Nothing,
        (Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}), closuref, ref_cb, deref_cb)
    ccall((:g_closure_set_marshal, libgobject), Nothing,
        (Ptr{Nothing}, Ptr{Nothing}), closuref, JuliaClosureMarshal::Ptr{Nothing})
    return ccall((:g_signal_connect_closure, libgobject), Culong,
        (Ptr{GObject}, Ptr{UInt8}, Ptr{Nothing}, Cint), w, bytestring(sig), closuref, after)
end
function GClosureMarshal(closuref::Ptr{Nothing}, return_value::Ptr{GValue}, n_param_values::Cuint,
                         param_values::Ptr{GValue}, invocation_hint::Ptr{Nothing}, marshal_data::Ptr{Nothing})
    @assert sizeof_gclosure > 0
    closure_env = convert(Ptr{Any}, closuref + sizeof_gclosure)
    cb = unsafe_load(closure_env, 1)::Function
    gtk_calling_convention = (0 != unsafe_load(convert(Ptr{Int}, closure_env),  2))
    params = Vector{Any}(undef, n_param_values)
    g_siginterruptible(cb) do
        if gtk_calling_convention
            # compatibility mode, if we must
            param_types, user_data = unsafe_load(closure_env, 2)::Array{Any, 1}
            length(param_types) + 1 == n_param_values || error("GCallback called with the wrong number of parameters")
            for i = 1:n_param_values
                gv = Ref(param_values, i)
                gtyp = gv[].g_type
                # avoid auto-unboxing for some builtin types in gtk_calling_convention mode
                if g_isa(gtyp, g_type(GObject))
                    params[i] = ccall((:g_value_get_object, libgobject), Ptr{GObject}, (Ptr{GValue},), gv)
                elseif g_isa(gtyp, g_type(GBoxed))
                    params[i] = ccall((:g_value_get_boxed, libgobject), Ptr{Nothing}, (Ptr{GValue},), gv)
                elseif g_isa(gtyp, g_type(AbstractString))
                    params[i] = ccall((:g_value_get_string, libgobject), Ptr{Nothing}, (Ptr{GValue},), gv)
                else
                    params[i] = gv[Any]
                end
                if i > 1
                    params[i] = convert(param_types[i - 1], params[i])
                end
            end
            push!(params, user_data)
        else
            for i = 1:n_param_values
                r=Ref(unsafe_load(param_values, i))
                params[i] = r[Any]
            end
        end
        # note: make sure not to leak any of the GValue objects into this task switch, since many of them were alloca'd
        retval = cb(params...) # widget, args...
        if return_value != C_NULL && retval !== nothing
            gtyp = unsafe_load(return_value).g_type
            if gtyp != g_type(Nothing) && gtyp != 0
                try
                    return_value[] = gvalue(retval)
                catch
                    @async begin # make this async to prevent task switches from being present right here
                        blame(cb)
                        println("ERROR: failed to set return value of type $(typeof(retval)); did your callback return an unintentional value?")
                    end
                end
            end
        end
    end
    return nothing
end

function blame(@nospecialize(cb))
    @warn "Executing $cb:"
end

signal_handler_disconnect(w::GObject, handler_id::Culong) =
    ccall((:g_signal_handler_disconnect, libgobject), Nothing, (Ptr{GObject}, Culong), w, handler_id)

signal_handler_block(w::GObject, handler_id::Culong) =
    ccall((:g_signal_handler_block, libgobject), Nothing, (Ptr{GObject}, Culong), w, handler_id)

signal_handler_unblock(w::GObject, handler_id::Culong) =
    ccall((:g_signal_handler_unblock, libgobject), Nothing, (Ptr{GObject}, Culong), w, handler_id)

"""
    tf = signal_handler_is_connected(widget, id)

Return `true`/`false` depending on whether `widget` has a connected signal handler with
the given `id`.
"""
signal_handler_is_connected(w::GObject, handler_id::Culong) =
    ccall((:g_signal_handler_is_connected, libgobject), Cint, (Ptr{GObject}, Culong), w, handler_id) == 1

function signal_emit(w::GObject, sig::AbstractStringLike, ::Type{RT}, args...) where RT
    i = isa(sig, AbstractString) ? something(findfirst("::", sig), 0:-1) : (0:-1)
    if !isempty(i)
        detail = @quark_str sig[last(i) + 1:end]
        sig = sig[1:first(i)-1]
    else
        detail = UInt32(0)
    end
    signal_id = ccall((:g_signal_lookup, libgobject), Cuint, (Ptr{UInt8}, Csize_t), sig, G_OBJECT_CLASS_TYPE(w))
    return_value = RT === Nothing ? C_NULL : gvalue(RT)
    ccall((:g_signal_emitv, libgobject), Nothing, (Ptr{GValue}, Cuint, UInt32, Ptr{GValue}), gvalues(w, args...), signal_id, detail, return_value)
    RT === Nothing ? nothing : return_value[RT]
end

g_stack = nothing # need to call g_loop_run from only one stack
const g_yielded = Ref(false) # when true, use the `g_doatomic` queue to run sigatom functions
const g_doatomic = [] # (work, notification) scheduler queue
const g_sigatom_flag = Ref(false) # keep track of Base sigatomic state
function g_sigatom(@nospecialize(f)) # calls f, where f never throws (but this function may throw)
    global g_sigatom_flag, g_stack, g_doatomic
    prev = g_sigatom_flag[]
    stk = g_stack
    ct = current_task()
    if g_yielded[]
        @assert g_stack !== nothing && g_stack != ct && !prev
        push!(g_doatomic, (f, ct))
        return wait()
    end

    if !prev
        sigatomic_begin()
        g_sigatom_flag[] = true
    end
    ret = nothing
    try
        if g_stack === ct
            ret = f()
        else
            @assert g_stack === nothing && !prev
            g_stack = ct
            ret = f()
        end
    catch err
        g_stack = stk
        @assert g_sigatom_flag[]
        if !prev
            g_sigatom_flag[] = false
            sigatomic_end() # may throw SIGINT
        end
        Base.println("FATAL ERROR: Gtk state corrupted by error thrown in a callback:")
        Base.display_error(err, catch_backtrace())
        println()
        rethrow(err)
    end
    g_stack = stk
    @assert g_sigatom_flag[]
    if !prev
        g_sigatom_flag[] = false
        sigatomic_end() # may throw SIGINT
    end
    return ret
end
macro sigatom(f)
    return quote
        g_sigatom() do
            $(esc(f))
        end
    end
end

function g_siginterruptible(f::Base.Callable, @nospecialize(cb)) # calls f (which may throw), but this function never throws
    global g_sigatom_flag, g_stack
    prev = g_sigatom_flag[]
    @assert xor(prev, (current_task() !== g_stack))
    try
        if prev
            # also know that current_task() === g_stack
            g_sigatom_flag[] = false
            sigatomic_end() # may throw SIGINT
        end
        f()
    catch err
        bt = catch_backtrace()
        @async begin # make this async to prevent task switches from being present right here
            blame(cb)
            Base.display_error(err, bt)
            println()
        end
    end
    @assert !g_sigatom_flag[]
    if prev
        sigatomic_begin()
        g_sigatom_flag[] = true
    end
    nothing
end

sizeof_gclosure = 0
function __init__gtype__()
    global jlref_quark = quark"julia_ref"
    global sizeof_gclosure = GLib.WORD_SIZE
    closure = C_NULL
    while closure == C_NULL
        sizeof_gclosure += GLib.WORD_SIZE
        closure = ccall((:g_closure_new_simple, libgobject), Ptr{Nothing}, (Int, Ptr{Nothing}), sizeof_gclosure, C_NULL)
    end
    ccall((:g_closure_sink, libgobject), Nothing, (Ptr{Nothing},), closure)
    gtype_wrapper_cache_init()
end

const main_loop_initialized=Ref(false)

_g_callback(cb::Function) = Cint(cb())
function g_timeout_add(cb::Function, interval::Integer)
    callback = @cfunction(_g_callback, Cint, (Ref{Function},))
    ref, deref = gc_ref_closure(cb)
    return ccall((:g_timeout_add_full, libglib),Cint,
        (Cint, UInt32, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
        0, UInt32(interval), callback, ref, deref)
end

function g_idle_add(cb::Function)
    callback = @cfunction(_g_callback, Cint, (Ref{Function},))
    ref, deref = gc_ref_closure(cb)
    return ccall((:g_idle_add_full , libglib),Cint,
        (Cint, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
        0, callback, ref, deref)
end

# Shortcut for g_idle_add
macro idle_add(ex)
    quote
    g_idle_add() do
        $(esc(ex))
        return false
      end
    end
end

function iteration(timer)
    ccall((:g_main_context_iteration, libglib), Cint, (Ptr{Cvoid}, Cint), C_NULL, false)
end

function glib_main()
    t=Timer(iteration,0.01;interval=0.005)
    wait(t)
end

function start_main_loop()
    # if g_main_depth > 0, a glib main-loop is already running,
    # so we don't need to start a new one
    if G_.main_depth() == 0
        G_.MainLoop_new(nothing, true)
        global glib_main_task = schedule(Task(glib_main))
    end
end

function process_events()
    while ccall((:g_main_context_pending, libglib), Cint, (Ptr{Nothing},), C_NULL)!=0
        ccall((:g_main_context_iteration, libglib), Cint, (Ptr{Cvoid}, Cint), C_NULL, false)
    end
end

const exiting = Ref(false)
function __init__()
    if isdefined(GLib, :__init__bindeps__)
        GLib.__init__bindeps__()
    end
    global JuliaClosureMarshal = @cfunction(GClosureMarshal, Nothing,
        (Ptr{Nothing}, Ptr{GValue}, Cuint, Ptr{GValue}, Ptr{Nothing}, Ptr{Nothing}))
    exiting[] = false
    atexit(() -> (exiting[] = true))
    __init__gtype__()
    nothing
end
