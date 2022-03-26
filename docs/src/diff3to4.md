# Differences between Gtk.jl and Gtk4.jl

Gtk4.jl is very similar to Gtk.jl. Here is a summary of what's different.

## Properties

Properties can still be set and accessed using `get_gtk_property` and `set_gtk_property!`. However, `GAccessor` no longer exists and is replaced by the getter and setter methods defined in `G_`.

## GObject names

Gtk.ShortNames is no more.

## No showall

In GTK 4.0, widgets are shown by default, so `show` and `showall` are no longer necessary.

## Events

Due to changes in GTK 4.0, events are handled through "event controllers".
