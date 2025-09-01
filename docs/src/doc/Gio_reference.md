# Gio Reference

The Gio library contains functionality for I/O (most of which overlaps functionality in
the Julia Base library) and machinery for applications, such as actions and menus.

## Actions and action groups
```@docs
Gtk4.GLib.GSimpleAction(::AbstractString)
Gtk4.GLib.add_action
Gtk4.GLib.add_stateful_action
Gtk4.GLib.set_state
```

## Menus

```@docs
Gtk4.GLib.GMenuItem(::Any)
```

## GApplication

```@docs
Gtk4.GLib.GApplication(::Any,::Any)
Gtk4.GLib.run
```

## Miscellaneous

```@docs
Gtk4.GLib.cancel_after_delay
```
