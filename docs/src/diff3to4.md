# Differences between Gtk.jl and Gtk4.jl

Gtk4.jl is very similar to Gtk.jl. Here is a summary of what's different.

## Properties

GObject [properties](manual/properties.md) can still be set and accessed using `get_gtk_property` and `set_gtk_property!`. However, properties are now mapped onto Julia properties, so one can set a window title using `win.title = "My title"`. Also, ``GAccessor` no longer exists and is replaced by the getter and setter methods defined in `G_`. Whereas in Gtk.jl one could use `GAccessor.title(win,"My title")` to set the title, in Gtk4.jl the equivalent is `G_.set_title(win, "My title")`.

## Enums and Flags

In Gtk.jl, GTK's enum and flags types were turned into integer constants. In Gtk4.jl, these are now mapped onto Julia enums, specifically the implementations [CEnum.jl](https://github.com/JuliaInterop/CEnum.jl) for enums and [BitFlags.jl](https://github.com/jmert/BitFlags.jl) for flags. This improves understandability when a function returns an enum or flag, but the downside is the sometimes extreme length of the enum's name. To mitigate this, `convert` methods are defined for the most commonly used enums so that shorter symbols can be used instead of the full enum name. For example, `:h` can be used instead of `Gtk4.Constants.Orientation_HORIZONTAL`.

## GAccessor has been replaced with G_

The submodule `Gtk.GAccessor` contains getter and setter methods. The submodule `Gtk4.G_` contains [automatically generated methods](manual/methods.md), which include all methods in `GAccessor` and many more.

## GObject names

The equivalent of `Gtk.ShortNames` doesn't exist. All `GObject` types are mapped onto Julia types with the same name.

## No showall

In GTK 4.0, widgets are shown by default, so `show` is no longer necessary in most situations. Exceptions include `GtkDialog`s and `GtkApplicationWindow`s.

## No GtkContainer

In GTK 4.0, `GtkContainer` has been removed and most widgets derive directly from `GtkWidget`. Each class that can contain child widgets has its own functions for adding and/or removing them. In Gtk4.jl, collection interface methods like `push!` have been defined for relatively simple containers, such as `GtkBox` and `GtkWindow`. For widgets that have one child, such as `GtkWindow`, `getindex` and `setindex!` have also been defined, so that one can set a child widget using `window[] = child`.

## Events

Due to changes in GTK 4.0, events are handled through "event controllers".
