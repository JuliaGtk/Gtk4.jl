_g_callback(cb::Function) = Cint(cb())

"""
    g_timeout_add(f, interval)

Add a function `f` that will be called every `interval` milliseconds by the GTK
main loop. The function is expected to return a `Cint`. If it returns 0, the
function will not be called again. Otherwise it will be called the next time.

Related GTK function: [`g_timeout_add`()]($(gtkdoc_func_url("glib","timeout_add")))
"""
function g_timeout_add(cb::Function, interval::Integer)
    callback = @cfunction(_g_callback, Cint, (Ref{Function},))
    ref, deref = gc_ref_closure(cb)
    return ccall((:g_timeout_add_full, libglib),Cint,
        (Cint, UInt32, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
        0, UInt32(interval), callback, ref, deref)
end

"""
    g_idle_add(f)

Add a Julia function `f` that will be called when there are no higher priority
GTK events to be processed. This function can be used from any thread.

See also [`@idle_add`](@ref).

Related GTK function: [`g_idle_add`()]($(gtkdoc_func_url("glib","idle_add")))
"""
function g_idle_add(cb::Function)
    callback = @cfunction(_g_callback, Cint, (Ref{Function},))
    ref, deref = gc_ref_closure(cb)
    return ccall((:g_idle_add_full , libglib),Cint,
        (Cint, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
        0, callback, ref, deref)
end

"""
    @idle_add(ex)

Create a function from an expression `ex` that will be called when there are no
higher priority GTK events to be processed. This function can be used from any
thread.

See also [`g_idle_add`](@ref).

Related GTK function: [`g_idle_add`()]($(gtkdoc_func_url("glib","idle_add")))
"""
macro idle_add(ex)
    quote
    g_idle_add() do
        $(esc(ex))
        return false
      end
    end
end

const g_main_running = Ref{Bool}(true)

glib_main() = GLib.g_sigatom() do
    # gtk_main() was deprecated in GTK 4.0, hence we iterate the loop ourselves
    while g_main_running[]
        ccall((:g_main_context_iteration, libglib), Cint, (Ptr{Cvoid}, Cint), C_NULL, true)
    end
end

"""
    start_main_loop()

If the default GLib main event loop is not already running, start a Julia task
that runs it.

See also [`stop_main_loop`](@ref).
"""
function start_main_loop()
    # if g_main_depth > 0, a glib main-loop is already running,
    # so we don't need to start a new one
    if ccall((:g_main_depth, libglib), Cint, ()) == 0
        global glib_main_task = schedule(Task(glib_main))
    end
end

"""
    stop_main_loop()

Stops the default GLib main loop after the next iteration. Does not affect loop
operation if GApplication's `run()` method is being used instead of
`GLib.start_main_loop()`.

See also [`start_main_loop`](@ref).
"""
function stop_main_loop()
    g_main_running[] = false
    ccall((:g_main_context_wakeup, libglib), Cvoid, (Ptr{Cvoid},), C_NULL)
end

GApplication(id = nothing, flags = GLib.ApplicationFlags_FLAGS_NONE) = G_.Application_new(id,flags)

function run(app::GApplication)
    ccall(("g_application_run", libgio), Int32, (Ptr{GObject}, Int32, Ptr{Cstring}), app, 0, C_NULL)
end
register(app::GApplication) = G_.register(app, nothing)
activate(app::GApplication) = G_.activate(app)
