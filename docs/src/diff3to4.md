# Differences between Gtk.jl and Gtk4.jl

Gtk4.jl is very similar to Gtk.jl. Here is a summary of what's different.

## Properties

GObject properties can still be set and accessed using `get_gtk_property` and `set_gtk_property!`. However, properties are now mapped onto Julia properties, so one can set a window title using `win.title = "My title"`. Also, ``GAccessor` no longer exists and is replaced by the getter and setter methods defined in `G_`. Whereas in Gtk.jl one could use `GAccessor.title(win,"My title")` to set the title, in Gtk4.jl the equivalent is `G_.set_title(win, "My title")`.

## GObject names

Gtk.ShortNames is no more. All GObject types are mapped onto Julia types with the same name.

## No showall

In GTK 4.0, widgets are shown by default, so `show` is no longer necessary in most situations. Exceptions include `GtkDialog`s and `GtkApplicationWindow`s.

## No GtkContainer

In GTK 4.0, `GtkContainer` has been removed and most widgets derive directly from `GtkWidget`. Each class that can contain child widgets has its own functions for adding and/or removing them. In Gtk4.jl, collection interface methods like `push!` have been defined for relatively simple containers, such as `GtkBox` and `GtkWindow`. For widgets that have one child, such as `GtkWindow`, `getindex` and `setindex!` have also been defined, so that one can set a child widget using `window[] = child`.

## Events

Due to changes in GTK 4.0, events are handled through "event controllers".
