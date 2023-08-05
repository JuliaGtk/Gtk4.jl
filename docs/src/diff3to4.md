# Differences between Gtk.jl and Gtk4.jl

Gtk4.jl builds on and is very similar to Gtk.jl. Here is a summary of what's different.

## Properties

GObject [properties](manual/properties.md) can still be set and accessed using `get_gtk_property` and `set_gtk_property!`. However, properties are now mapped onto Julia properties, so one can set a window title using `win.title = "My title"`.  Also, the submodule `GAccessor` no longer exists. In Gtk4.jl, getter and setter methods are in the main `Gtk4` module, but most are not exported. Whereas in Gtk.jl one uses `GAccessor.title(win, "My title")` to set the title, in Gtk4.jl the equivalent is `Gtk4.title(win, "My title")`.

## Constants, enums, and flags

GTK constants in Gtk4.jl are in the main module instead of a `Constants` submodule.

In Gtk.jl, GTK's enum and flags constants are turned into integers. In Gtk4.jl, these are now mapped onto Julia enums, specifically the implementations [CEnum.jl](https://github.com/JuliaInterop/CEnum.jl) for enums and [BitFlags.jl](https://github.com/jmert/BitFlags.jl) for flags. This improves understandability when a function returns an enum or flag, but the downside is the sometimes extreme length of the enum's name. To mitigate this, `convert` methods are defined for commonly used enums so that shorter symbols can be used instead of the full enum name. For example, `:h` can be used instead of `Gtk4.Orientation_HORIZONTAL` in `GtkBox(orientation, spacing)`.

## G_ contains automatically generated methods

In Gtk.jl, the submodule `Gtk.GAccessor` contains getter and setter methods, which often correspond to object properties. In Gtk4.jl, the submodule `Gtk4.G_` contains [automatically generated methods](manual/methods.md), which include all methods in `GAccessor` and many more. These methods directly call the C functions in libgtk and thus use 0-based indexing. Where possible, they translate between Julia types and C types, for example converting `nothing` to `C_NULL` and vice versa.

For consistency, the getter and setter methods in `G_` keep their full names, including "set" and "get". For example, to set the title of a window in Gtk4.jl use `G_.set_title(w, "text")` rather than `GAccessor.title(w, "text")` as in Gtk.jl.

## GObject and struct names

The equivalent of `Gtk.ShortNames` doesn't exist. All `GObject` types are mapped onto Julia types with the same name. Leaving out the namespace, as is done in the Python `pygobject` bindings, would have led to name collisions between Gtk types and Julia types or between Gtk and other GObject libraries.

## No showall

In GTK 4, widgets are shown by default, so `showall` does not exist, and calling `show` is no longer necessary in most situations. Exceptions include `GtkDialog`s and `GtkApplicationWindow`s.

## No GtkContainer

In GTK 4, `GtkContainer` has been removed and most widgets derive directly from `GtkWidget`. Each class that can contain child widgets has its own functions for adding and/or removing them. In Gtk4.jl, collection interface methods like `push!` have been defined for containers that hold many widgets, such as `GtkBox`. For widgets that have one child, such as `GtkWindow`, `getindex` and `setindex!` have been defined, so that one can set a child widget using `window[] = child`.

## Events

Events such as button presses are handled through "event controllers" in GTK 4.

## Dialogs

Dialogs no longer have a `run` method that takes over the GLib main loop while waiting for the user's response.

## GLib event loop

The GLib main loop starts automatically if Julia is in an interactive session. If not, you will have to start it by calling `start_main_loop` or by creating a `GtkApplication` and calling `run` (see the example `application.jl`).

## MutableTypes and GValue

All uses of `mutable` from Gtk.jl's `GLib.MutableTypes` should be replaced by Julia's `Ref`.
The type of a `GValue` can be set using `settype!` rather than `setindex!`.

## More information

The GTK docs have a [migration guide](https://docs.gtk.org/gtk4/migrating-3to4.html) with detailed recommendations for migrating C code from GTK version 3 to version 4. Much of that advice applies to Julia code.
