"""
    g_timeout_add(f, interval, priority=PRIORITY_DEFAULT)

Add a function `f` that will be called every `interval` milliseconds by the GTK
main loop. If the function returns `true`, it will be called again after
another `interval` milliseconds. If it returns `false` it will not be called
again. The optional `priority` argument, which is an integer, sets the priority
of the event source (smaller is higher priority). The GLib main loop uses this
priority value to decide what sources to handle next.

This function returns an event source ID that can be used with `g_source_remove`
to stop the timeout externally.

Related GTK function: [`g_timeout_add`()]($(gtkdoc_func_url("glib","timeout_add")))
"""
function g_timeout_add(cb::Function, interval::Integer, priority=PRIORITY_DEFAULT)
    #is_loop_running() || @warn("g_timeout_add needs GLib main loop to be running.")
    callback = @cfunction(GSourceFunc, Cint, (Ref{Function},))
    ref, deref = gc_ref_closure(cb)
    return ccall((:g_timeout_add_full, libglib),Cint,
        (Cint, UInt32, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
        Int32(priority), UInt32(interval), callback, ref, deref)
end

"""
    g_idle_add(f, priority=PRIORITY_DEFAULT_IDLE)

Add a Julia function `f` that will be called when there are no higher priority
GTK events to be processed. This function can be used from any thread. The
optional `priority` argument, which is an integer, sets the priority of the
event source (smaller is higher priority). The GLib main loop uses this priority
value to decide what sources to handle next.

See also [`@idle_add`](@ref).

Related GTK function: [`g_idle_add_full`()]($(gtkdoc_func_url("glib","idle_add_full")))
"""
function g_idle_add(cb::Function, priority=PRIORITY_DEFAULT_IDLE)
    #is_loop_running() || @warn("g_idle_add needs GLib main loop to be running.")
    callback = @cfunction(GSourceFunc, Cint, (Ref{Function},))
    ref, deref = gc_ref_closure(cb)
    return ccall((:g_idle_add_full , libglib),Cint,
        (Cint, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
        Int32(priority), callback, ref, deref)
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

"""
    g_source_remove(id::Integer)

Remove the event source identified by `id` from the GLib main loop. The `id` is
returned by `g_idle_add` and `g_timeout_add`. The main loop reuses `id`'s so care
should be taken that the source intended to be removed is still active.

Related GTK function: [`g_source_remove`()]($(gtkdoc_func_url("glib","source_remove")))
"""
g_source_remove(id) = G_.source_remove(id)

const g_main_running = Ref{Bool}(true)

glib_main() = g_sigatom() do
    # gtk_main() was deprecated in GTK 4.0, hence we iterate the loop ourselves
    while g_main_running[]
        ccall((:g_main_context_iteration, libglib), Cint, (Ptr{Cvoid}, Cint), C_NULL, true)
    end
end

"""
    is_loop_running() -> Bool

Return true if the default GLib main event loop is running.

Related GTK function: [`g_main_depth`()]($(gtkdoc_func_url("glib","main_depth")))
"""
is_loop_running() = (G_.main_depth() != 0)

"""
    start_main_loop(wait=false)

If the default GLib main event loop is not already running, start a Julia task
that runs it. Returns the task. If `wait` is true, it will block until the
main loop starts running.

See also [`stop_main_loop`](@ref).
"""
function start_main_loop(wait=false)
    @debug("Starting GLib main loop using g_main_context_iteration()")
    # if a glib main-loop is already running, we don't need to start a new one
    if !is_loop_running()
        g_main_running[] = true
        global glib_main_task = schedule(Task(glib_main))
    end
    if wait
        i=1
        while !is_loop_running()
            sleep(0.001)
            i+=1
            if i>1000
                @warn("Main loop is not starting, returning from start_main_loop() anyway!")
                break
            end
        end
    end
    glib_main_task
end

"""
    stop_main_loop(wait=false)

Stops the default GLib main loop after the next iteration. If `wait` is true, it will block until the
main loop stops running.

Does not affect loop operation if GApplication's `run()` method is being used instead of
`GLib.start_main_loop()`.

See also [`start_main_loop`](@ref).
"""
function stop_main_loop(wait=false)
    g_main_running[] || return nothing  # we are either already stopped or in a GApplication
    g_main_running[] = false
    ccall((:g_main_context_wakeup, libglib), Cvoid, (Ptr{Cvoid},), C_NULL)
    if wait
        i=1
        while is_loop_running()
            sleep(0.001)
            i+=1
            if i>1000
                @warn("Main loop is not stopping, returning from stop_main_loop() anyway!")
                break
            end
        end
    end
    nothing
end

"""
    pause_main_loop(f)

Pauses the GLib event loop around a function. Restores the original state of the event loop after calling the function. This function does not pause the event loop if it is being run by a `GApplication`.
"""
function pause_main_loop(f)
    was_running = is_loop_running()
    if was_running && g_main_running[] == false
        @warn("GLib main loop is running, but not via `glib_main`. Pausing the main loop inside a GApplication is not currently supported, so the function will be called without pausing.")
        f()
        return
    end
    was_running && stop_main_loop(true)
    try
        f()
    finally
        was_running && start_main_loop(true)
    end
end

"""
    set_uv_loop_integration(s = "auto")

Change Gtk4.jl's libuv loop integration setting. The argument `s` should be "auto" to use Gtk4.jl's default
setting or "enabled" or "disabled" to override this. This setting will take effect after restarting Julia.

Enabling libuv loop integration may improve REPL response on some platforms (Mac) but negatively impacts multithreaded
performance. This function has no effect when running on Windows.
"""
function set_uv_loop_integration(s = "auto")
    s in ["auto", "enabled", "disabled"] || error("""valid arguments are "auto", "enabled", and "disabled".""")
    @set_preferences!("uv_loop_integration" => s)
    @info("Setting will take effect after restarting Julia.")
end

"""
    get_uv_loop_integration() -> String

Get Gtk4.jl's libuv loop integration setting: "auto", "enabled", or "disabled".

See also [`set_uv_loop_integration`](@ref).
"""
get_uv_loop_integration() = @load_preference("uv_loop_integration", "auto")

"""
    is_uv_loop_integration_enabled() -> Bool

Get whether Gtk4.jl's libuv loop integration is enabled.

See also [`set_uv_loop_integration`](@ref).
"""
is_uv_loop_integration_enabled() = uv_int_enabled[]

"""
    GApplication(id = nothing, flags = GLib.ApplicationFlags_FLAGS_NONE)

Create a `GApplication` with DBus id `id` and flags.

Related GLib function: [`g_application_new`()]($(gtkdoc_method_url("gio","Application","new")))
"""
GApplication(id = nothing, flags = ApplicationFlags_FLAGS_NONE) = G_.Application_new(id,ApplicationFlags_FLAGS_NONE)

"""
    run(app::GApplication)

Calls `g_application_run`, starting the main loop. If the loop is already running, this function will stop it and emit a warning before
starting the application loop.
"""
function run(app::GApplication)
    if is_loop_running()
        stop_main_loop(true)
        @warn("A main loop is already running. Stopping it and starting a new one for the application.")
    end
    ccall(("g_application_run", libgio), Int32, (Ptr{GObject}, Int32, Ptr{Cstring}), app, 0, C_NULL)
end
register(app::GApplication) = G_.register(app, nothing)
activate(app::GApplication) = G_.activate(app)
quit(app::GApplication) = G_.quit(app)
