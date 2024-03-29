# GLib Reference

## Event loop

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
Gtk4.GLib.run
```

## REPL helper functions

These are functions that are intended to be used in the REPL to look up
information about GObjects and their properties and signals.

```@docs
Gtk4.GLib.propertyinfo
Gtk4.GLib.gtk_propertynames
Gtk4.GLib.signalnames
Gtk4.GLib.signal_return_type
Gtk4.GLib.signal_argument_types
```

## Properties

```@docs
Gtk4.GLib.on_notify
Gtk4.GLib.bind_property
Gtk4.GLib.unbind_property
Gtk4.GLib.setproperties!
Gtk4.GLib.set_gtk_property!
Gtk4.GLib.get_gtk_property
```

## Signals
```@docs
Gtk4.GLib.signal_handler_is_connected
Gtk4.GLib.signal_handler_disconnect
Gtk4.GLib.signal_handler_block
Gtk4.GLib.signal_handler_unblock
Gtk4.GLib.signal_emit
Gtk4.GLib.waitforsignal
```

## Actions and action groups
```@docs
Gtk4.GLib.GSimpleAction
Gtk4.GLib.add_action
Gtk4.GLib.add_stateful_action
Gtk4.GLib.set_state
```

## GObject type system
```@docs
Gtk4.GLib.g_type
Gtk4.GLib.find_leaf_type
```
