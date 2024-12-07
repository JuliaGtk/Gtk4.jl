# GObject Reference

The GObject library contains GLib's type system, including the `GObject` type, subclasses
of which can include properties and signals.

## Properties

Properties of `GObject` are mapped onto Julia properties.

```@docs
Gtk4.GLib.set_gtk_property!
Gtk4.GLib.get_gtk_property
Gtk4.GLib.bind_property
Gtk4.GLib.unbind_property
Gtk4.GLib.setproperties!
```

These are functions that are intended to be used in the REPL to look up
information about `GObject`s and their properties and signals.

```@docs
Gtk4.GLib.propertyinfo
Gtk4.GLib.gtk_propertynames
```

## Signals

```@docs
Gtk4.GLib.signal_handler_is_connected
Gtk4.GLib.signal_handler_disconnect
Gtk4.GLib.signal_handler_block
Gtk4.GLib.signal_handler_unblock
Gtk4.GLib.signal_emit
Gtk4.GLib.waitforsignal
Gtk4.GLib.on_notify
Gtk4.GLib.signalnames
Gtk4.GLib.signal_return_type
Gtk4.GLib.signal_argument_types
```

## GObject type system

These functions are not typically needed by most users.

```@docs
Gtk4.GLib.g_type
Gtk4.GLib.find_leaf_type
```
