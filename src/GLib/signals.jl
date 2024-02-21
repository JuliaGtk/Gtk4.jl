# First the version of `signal_connect` that takes the return type and argument types and passes a 
# function and closure to `g_signal_connect_data`.

# id = signal_connect(widget, :event, Nothing, (ArgsT...)) do ptr, evt_args..., closure
#    stuff
# end
function signal_connect(@nospecialize(cb::Function), w::GObject, sig::AbstractStringLike,
        ::Type{RT}, param_types::Tuple, after::Bool = false, user_data::CT = w) where {CT, RT}
    # could use signal_query to check RT and param_types and throw an error if not correct
    signal_connect_generic(cb, w, sig, RT, param_types, after, user_data)
end

function signal_connect_generic(@nospecialize(cb::Function), w::GObject, sig::AbstractStringLike,
        ::Type{RT}, param_types::Tuple, after::Bool = false, user_data::CT = w) where {CT, RT}
    callback = cfunction_(cb, RT, tuple(Ptr{GObject}, param_types..., Ref{CT}))
    ref, deref = gc_ref_closure(user_data)
    return ccall((:g_signal_connect_data, libgobject), Culong,
                 (Ptr{GObject}, Ptr{UInt8}, Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}, GEnum),
                 w,
                 bytestring(sig),
                 callback,
                 ref,
                 deref,
                 after ? ConnectFlags_AFTER : 0)
end

# Next the more user friendly version, which passes everything as GValues.

# id = signal_connect(widget, :event) do obj, evt_args...
#    stuff
# end
function signal_connect(@nospecialize(cb::Function), w::GObject, sig::AbstractStringLike, after::Bool = false)
    _signal_connect(cb, w, sig, after, false, nothing, nothing)
end
function _signal_connect(@nospecialize(cb::Function), w::GObject, sig::AbstractStringLike, after::Bool, gtk_call_conv::Bool, param_types, user_data)
    @assert sizeof_gclosure > 0
    closuref = ccall((:g_closure_new_object, libgobject), Ptr{Nothing}, (Cuint, Ptr{GObject}), sizeof_gclosure::Int + Sys.WORD_SIZE * 2, w)
    closure_env = convert(Ptr{Ptr{Nothing}}, closuref + sizeof_gclosure)
    unsafe_store!(convert(Ptr{Int}, closure_env), 0, 2)
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
    @assert gtk_calling_convention == false
    params = Vector{Any}(undef, n_param_values)
    g_siginterruptible(cb) do
        for i = 1:n_param_values
            r=Ref(unsafe_load(param_values, i))
            params[i] = r[Any]
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

# Shortcut for creating callbacks that don't corrupt Gtk state if
# there's an error
macro guarded(ex...)
    retval = nothing
    if length(ex) == 2
        retval = ex[1]
        ex = ex[2]
    else
        length(ex) == 1 || error("@guarded requires 1 or 2 arguments")
        ex = ex[1]
    end
    # do-block syntax
    if ex.head == :do && length(ex.args) >= 2 && ex.args[2].head == :->
        newbody = _guarded(ex.args[2], retval)
        ret = deepcopy(ex)
        ret.args[2] = Expr(ret.args[2].head, ret.args[2].args[1], newbody)
        return esc(ret)
    end
    newbody = _guarded(ex, retval)
    esc(Expr(ex.head, ex.args[1], newbody))
end

function _guarded(ex, retval)
    isa(ex, Expr) && (
        ex.head == :-> ||
        (ex.head == :(=) && isa(ex.args[1], Expr) && ex.args[1].head == :call) ||
        ex.head == :function
    ) || error("@guarded requires an expression defining a function")
    quote
        begin
            try
                $(ex.args[2])
            catch err
                @warn("Error in @guarded callback", exception=(err, catch_backtrace()))
                $retval
            end
        end
    end
end

function blame(@nospecialize(cb))
    @warn "Executing $cb:"
end

"""
    signal_handler_disconnect(w::GObject, id)

Disconnect a signal handler from a widget `w` by its `id`.
"""
signal_handler_disconnect(w::GObject, handler_id::Culong) =
    ccall((:g_signal_handler_disconnect, libgobject), Nothing, (Ptr{GObject}, Culong), w, handler_id)

"""
    signal_handler_block(w::GObject, id)

Temporarily block a signal handler from running on a `GObject` instance.

See also [`signal_handler_unblock`](@ref).
"""
signal_handler_block(w::GObject, handler_id::Culong) =
    ccall((:g_signal_handler_block, libgobject), Nothing, (Ptr{GObject}, Culong), w, handler_id)

"""
    signal_handler_block(w::GObject, id)

Unblock a signal handler that had been previously blocked.

See also [`signal_handler_block`](@ref).
"""
signal_handler_unblock(w::GObject, handler_id::Culong) =
    ccall((:g_signal_handler_unblock, libgobject), Nothing, (Ptr{GObject}, Culong), w, handler_id)

"""
    signal_handler_is_connected(widget, id) -> Bool

Return `true`/`false` depending on whether `widget` has a connected signal handler with
the given `id`.
"""
signal_handler_is_connected(w::GObject, handler_id::Culong) =
    ccall((:g_signal_handler_is_connected, libgobject), Cint, (Ptr{GObject}, Culong), w, handler_id) == 1

"""
    signal_emit(w::GObject, sig::AbstractStringLike, ::Type{RT}, args...) where RT

Cause an object signal to be emitted. The return type `RT` and the correct number of arguments (of the correct type) must be provided. The argument list should exclude the `user_data` argument.
"""
function signal_emit(w::GObject, sig::AbstractStringLike, ::Type{RT}, args...) where RT
    i = isa(sig, AbstractString) ? something(findfirst("::", sig), 0:-1) : (0:-1)
    if !isempty(i)
        detail = quark_from_string(sig[last(i) + 1:end])
        sig = sig[1:first(i)-1]
    else
        detail = UInt32(0)
    end
    signal_id = ccall((:g_signal_lookup, libgobject), Cuint, (Ptr{UInt8}, Csize_t), sig, G_OBJECT_CLASS_TYPE(w))
    return_value = RT === Nothing ? C_NULL : gvalue(RT)
    gvals = gvalues(w, args...)
    GC.@preserve gvals return_value ccall((:g_signal_emitv, libgobject), Nothing, (Ptr{GValue}, Cuint, UInt32, Ptr{GValue}), gvals, signal_id, detail, return_value)
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
        @assert g_stack !== nothing
        b = (g_stack != ct)::Bool
        @assert b
        @assert !prev
        push!(g_doatomic, (f, ct))
        return wait()
    end

    if !prev
        Base.sigatomic_begin()
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
            Base.sigatomic_end() # may throw SIGINT
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
        Base.sigatomic_end() # may throw SIGINT
    end
    return ret
end

function g_siginterruptible(f::Base.Callable, @nospecialize(cb)) # calls f (which may throw), but this function never throws
    global g_sigatom_flag, g_stack
    prev = g_sigatom_flag[]
    @assert xor(prev, (current_task() !== g_stack))
    try
        if prev
            # also know that current_task() === g_stack
            g_sigatom_flag[] = false
            Base.sigatomic_end() # may throw SIGINT
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
        Base.sigatomic_begin()
        g_sigatom_flag[] = true
    end
    nothing
end

function g_yield(data)
    global g_yielded, g_doatomic
    while true
        g_yielded[] = true
        g_siginterruptible(yield, yield)
        g_yielded[] = false
        run_delayed_finalizers()

        if isempty(g_doatomic)
            return Int32(true)
        else
            f, t = pop!(g_doatomic)
            ret = nothing
            iserror = false
            try
                ret = f()
            catch err
                iserror = true
                ret = err
            end
            schedule(t, ret, error = iserror)
        end
    end
end

mutable struct _GPollFD
  @static Sys.iswindows() ? fd::Int : fd::Cint
  events::Cushort
  revents::Cushort
  _GPollFD(fd, ev) = new(fd, ev, 0)
end

mutable struct _GSourceFuncs
    prepare::Ptr{Nothing}
    check::Ptr{Nothing}
    dispatch::Ptr{Nothing}
    finalize::Ptr{Nothing}
    closure_callback::Ptr{Nothing}
    closure_marshal::Ptr{Nothing}
end
function new_gsource(source_funcs::_GSourceFuncs)
    sizeof_gsource = Sys.WORD_SIZE
    gsource = C_NULL
    while gsource == C_NULL
        sizeof_gsource += Sys.WORD_SIZE
        gsource = ccall((:g_source_new, libglib), Ptr{Nothing}, (Ptr{_GSourceFuncs}, Int), Ref(source_funcs), sizeof_gsource)
    end
    gsource
end

expiration = UInt64(0)
_isempty_workqueue() = isempty(Base.Workqueue)
uv_loop_alive(evt) = ccall(:uv_loop_alive, Cint, (Ptr{Nothing},), evt) != 0

function uv_prepare(src::Ptr{Nothing}, timeout::Ptr{Cint})
    global expiration, uv_pollfd
    local tmout_ms::Cint
    evt = Base.eventloop()
    if !_isempty_workqueue()
        tmout_ms = 0
    elseif !uv_loop_alive(evt)
        tmout_ms = -1
    elseif uv_pollfd.revents != 0
        tmout_ms = 0
    else
        ccall(:uv_update_time, Nothing, (Ptr{Nothing},), evt)
        tmout_ms = ccall(:uv_backend_timeout, Cint, (Ptr{Nothing},), evt)
        tmout_min::Cint = (uv_pollfd::_GPollFD).fd == -1 ? 10 : 5000
        if tmout_ms < 0 || tmout_ms > tmout_min
            tmout_ms = tmout_min
        end
    end
    timeout != C_NULL && unsafe_store!(timeout, tmout_ms)
    if tmout_ms < 0
        expiration = typemax(UInt64)
    elseif tmout_ms > 0
        now = ccall((:g_source_get_time, libglib), UInt64, (Ptr{Nothing},), src)
        expiration = convert(UInt64, now + tmout_ms * 1000)
    else #tmout_ms == 0
        expiration = UInt64(0)
    end
    Int32(tmout_ms == 0)
end
function uv_check(src::Ptr{Nothing})
    global expiration
    ex = expiration::UInt64
    if !_isempty_workqueue()
        return Int32(1)
    elseif !uv_loop_alive(Base.eventloop())
        return Int32(0)
    elseif ex == 0
        return Int32(1)
    elseif uv_pollfd.revents != 0
        return Int32(1)
    else
        now = ccall((:g_source_get_time, libglib), UInt64, (Ptr{Nothing},), src)
        return Int32(ex <= now)
    end
end
function uv_dispatch(src::Ptr{Nothing}, callback::Ptr{Nothing}, data)
    return ccall(callback, Cint, (UInt,), data)
end

sizeof_gclosure = 0
function __init__gtype__()
    global jlref_quark = quark"julia_ref"
    global sizeof_gclosure = Sys.WORD_SIZE
    closure = C_NULL
    while closure == C_NULL
        sizeof_gclosure += Sys.WORD_SIZE
        closure = ccall((:g_closure_new_simple, libgobject), Ptr{Nothing}, (Int, Ptr{Nothing}), sizeof_gclosure, C_NULL)
    end
    ccall((:g_closure_sink, libgobject), Nothing, (Ptr{Nothing},), closure)
    gtype_wrapper_cache_init()
end

const uv_int_enabled=Ref(false)

function __init__gmainloop__()
    global uv_sourcefuncs = _GSourceFuncs(
        @cfunction(uv_prepare, Cint, (Ptr{Nothing}, Ptr{Cint})),
        @cfunction(uv_check, Cint, (Ptr{Nothing},)),
        @cfunction(uv_dispatch, Cint, (Ptr{Nothing}, Ptr{Nothing}, Int)),
        C_NULL, C_NULL, C_NULL)
    src = new_gsource(uv_sourcefuncs)
    ccall((:g_source_set_can_recurse, libglib), Nothing, (Ptr{Nothing}, Cint), src, true)
    ccall((:g_source_set_name, libglib), Nothing, (Ptr{Nothing}, Ptr{UInt8}), src, "uv loop")
    ccall((:g_source_set_callback, libglib), Nothing, (Ptr{Nothing}, Ptr{Nothing}, UInt, Ptr{Nothing}),
        src, @cfunction(g_yield, Cint, (UInt,)), 1, C_NULL)

    uv_int_setting = @load_preference("uv_loop_integration", "auto")
    if uv_int_setting == "enabled"
        uv_int_enabled[] = true
    elseif uv_int_setting == "disabled"
        uv_int_enabled[] = false
    elseif uv_int_setting == "auto"
        # enabled by default only on Macs in an interactive session, where it prevents REPL lag
        uv_int_enabled[] = Sys.isapple() && isinteractive()
    end
    uv_fd = !uv_int_enabled[] || Sys.iswindows() ? -1 : ccall(:uv_backend_fd, Cint, (Ptr{Nothing},), Base.eventloop())
    global uv_pollfd = _GPollFD(uv_fd, 0x1)
    if (uv_pollfd::_GPollFD).fd != -1
        ccall((:g_source_add_poll, libglib), Nothing, (Ptr{Nothing}, Ptr{_GPollFD}), src, Ref(uv_pollfd::_GPollFD))
    end

    ccall((:g_source_attach, libglib), Cuint, (Ptr{Nothing}, Ptr{Nothing}), src, C_NULL)
    ccall((:g_source_unref, libglib), Nothing, (Ptr{Nothing},), src)
    nothing
end

"""
    waitforsignal(obj::GObject, signal)

Returns when a GObject's signal is emitted. Can be used to wait for a window to
be closed.
"""
function waitforsignal(obj::GObject,signal)
  c = Condition()
  signal_connect(obj, signal) do w
      notify(c)
      return false
  end
  wait(c)
end

"""
    on_notify(f, object::GObject, property, user_data = object, after = false)

Connect a callback `f` to the object's "notify::property" signal that will be
called whenever the property changes. The callback signature should be
`f(::Ptr, param::Ptr{GParamSpec}, user_data)` and the function should return `nothing`.
"""
function on_notify(f, object::GObject, property::AbstractString, user_data = object, after = false)
    signal_connect_generic(f, object, "notify::$property", Nothing, (Ptr{GParamSpec},), after, user_data)
end
on_notify(f, object::GObject, property::Symbol, user_data = object, after = false) = on_notify(f, object, String(property), user_data, after)

# The following are overridden by GI for each subtype of GObject

"""
    signalnames(::Type{T}) where T <: GObject

Returns a list of the names of supported signals for T.
"""
function signalnames(::Type{GObject})
    [:notify]
end

"""
    signal_return_type(::Type{T}, name::Symbol) where T <: GObject

Gets the return type for the callback for the signal `name` of a `GObject` type
(for example `GtkWidget`).
"""
function signal_return_type(::Type{GObject},name::Symbol)
    name === :notify || KeyError(name)
    Nothing
end

"""
    signal_argument_types(::Type{T}, name::Symbol) where T <: GObject

Gets the argument types for the callback for the signal `name` of a `GObject` type
(for example `GtkWidget`).
"""
function signal_argument_types(::Type{GObject},name::Symbol)
    name === :notify || KeyError(name)
    (Ptr{GParamSpec},)
end
