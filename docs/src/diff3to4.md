# Differences between Gtk.jl and Gtk4.jl

Gtk4.jl is very similar to Gtk.jl. Here is a summary of what's different.

## Properties

GObject properties can still be set and accessed using `get_gtk_property` and `set_gtk_property!`. However, properties are now mapped onto Julia properties, so one can set a window title using `win.title = "My title"`. Also, ``GAccessor` no longer exists and is replaced by the getter and setter methods defined in `G_`. Whereas in Gtk.jl one could use `GAccessor.title(win,"My title")` to set the title, in Gtk4.jl the equivalent is `G_.set_title(win, "My title")`.

## GObject names

Gtk.ShortNames is no more. All GObject types are mapped onto Julia types with the same name.

## No showall

In GTK 4.0, widgets are shown by default, so `show` and `showall` are no longer necessary.

## Events

Due to changes in GTK 4.0, events are handled through "event controllers".
