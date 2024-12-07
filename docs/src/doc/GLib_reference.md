# GLib Reference

The GLib submodule wraps functions and types in the [GLib](https://docs.gtk.org/gLib) (libglib), [GObject](https://docs.gtk.org/gobject) (libgobject),
and [Gio](https://docs.gtk.org/gio) (libgio) C libraries. Julia users probably don't care where things are defined
in the C libraries, but we organize things in this documentation according to that same
scheme to mirror the [C API documentation](https://docs.gtk.org), which is the ultimate
source of information for understanding how and why things work.

The GLib library contains functions and types that are useful for writing C code, but most
are not useful in Julia because they duplicate functionality in Julia's Base library. The
important functions in GLib for users of this package concern the GLib event loop, the
`GVariant` type, and error/warning message handling.

## Event loop

The GLib event loop is used by GTK to schedule and coordinate user input, drawing, etc.
much like Julia uses the libuv event loop. Gtk4.jl inherited Gtk.jl's integration of the
two event loops. There are situations when you may want to stop or pause the GLib main
loop (for example, [ProfileView.jl](https://github.com/timholy/ProfileView.jl) does this
while running `@profile`). There are also many cases when you have to be careful about how
to call functions because some of the API is not thread safe.

```@docs
Gtk4.GLib.is_loop_running
Gtk4.GLib.pause_main_loop
Gtk4.GLib.start_main_loop
Gtk4.GLib.stop_main_loop
Gtk4.GLib.@idle_add
Gtk4.GLib.g_idle_add
Gtk4.GLib.g_timeout_add
Gtk4.GLib.g_source_remove
Gtk4.GLib.get_uv_loop_integration
Gtk4.GLib.set_uv_loop_integration
Gtk4.GLib.is_uv_loop_integration_enabled
```

## GVariant

The `GVariant` type is used as a container in the [Actions](@ref) system. The types that
can be stored and accessed in Gtk4.jl are currently: `Bool`, `UInt8`, `Int8`, `UInt16`,
`Int16`, `UInt32`, `Int32`, `UInt64`, `Int64`, `Float64`, `String`, and tuples containing
these.

The only time you're going to need to deal with `GVariant`s is when you create them to
use as a parameter or to set the state of an action, or access values within `GVariant`s
in action handlers.

```@docs
Gtk4.GLib.GVariant
Gtk4.GLib.GVariantType
```

## Message handling

GLib has a facility for emitting informational messages, warnings, and critical warnings.
When C functions emit these they show up in the Julia REPL. In many cases these are unavoidable or at least pretty harmless, and they are a common source of complaints from users of Gtk4 or downstream packages. One can filter these out by providing a "log writer" function.

```@docs
Gtk4.GLib.suppress_C_messages
Gtk4.GLib.show_C_messages
Gtk4.GLib.set_log_writer_func
```

