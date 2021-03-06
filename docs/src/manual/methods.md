# Automatically generated methods

The functions defined in this package all wrap `ccall`'s of GTK functions in a Julian and hopefully user friendly way. In Gtk4.jl many of these wrappers use methods automatically generated using GObject introspection, which can be found in a submodule `G_`. If you don't see a particular functionality wrapped, you can call these autogenerated functions yourself. The names of these functions and methods are intended to be easy to predict from the corresponding C library function names, and most are the same as in the pygobject bindings for GTK.

The autogenerated methods in `G_`, like the corresponding C functions, use 0-based indexing, while the more user-friendly wrappers outside `G_` use 1-based indexing.
Some types of methods are not yet supported. For example, methods involving callbacks must be wrapped by using `ccall`.

The following table lists a few examples.

| C function | Gtk4.G_ Julia method | Comments |
| :--- | :--- | :--- |
| `void gtk_window_add_child (GtkWindow* window, GtkWidget* child)` | `add_child (window::GtkWindow, child::GtkWidget)` | C arguments mapped directly onto Julia arguments
| `GtkStackPage* gtk_stack_add_child (GtkStack* stack, GtkWidget* child)` | `add_child (stack::GtkStack, child::GtkWidget)` | many widgets have `add_child` methods, but we dispatch using type of first argument
| `void gtk_builder_add_from_file (GtkBuilder* builder, const gchar* filename, GError** error)` | `add_from_file (builder::GtkBuilder, filename::AbstractString)` | if `ccall` fills GError argument, a Julia exception is thrown
| `guint gtk_get_major_version ()` | `get_major_version ()` | returns an Int32
| `void gtk_rgb_to_hsv (float r, float g, float b, float* h, float* s, float* v)` | `rgb_to_hsv (r::Real, g::Real, b::Real)` | GObject introspection tells us that `h`, `s`, and `v` are outputs. Julia method returns `(h, s, v)`
