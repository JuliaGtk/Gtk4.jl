GI.jl
======

Julia bindings using libgobject-introspection.

This builds on https://github.com/bfredl/GI.jl

## Scope

This package outputs code that simplifies the creation of Julia packages that wrap GObject-based libraries.
It outputs constants (including enums and flags types), struct definitions, callback definitions, and function definitions that wrap `ccall`'s of GObject based libraries.
In function definitions, it uses [annotations](https://gi.readthedocs.io/en/latest/annotations/giannotations.html) to determine whether return values should be freed, whether pointer arguments can be optionally NULL, whether list outputs are NULL-terminated, which argument corresponds to the length of array inputs, which arguments are outputs and which are inputs, and more.
The primary advantage over manually writing `ccall`'s (as is done in Gtk.jl) is that it can rapidly cover an entire library, saving a lot of tedious work.
As new functionality is added to libraries, you just have to run GI.jl again and new code is generated.
The advantage over using Clang to generate wrappers is the fact that annotations provide important information, like whether outputs are "owned" or not, which arguments are closures or array lengths, and so on.
Disadvantages: the current implementation only extracts GI information on Linux, leading to potential bugs on other platforms.

This package is unregistered and it only works on Linux because it uses [gobject_introspection_jll](https://github.com/JuliaPackaging/Yggdrasil/tree/master/G/gobject_introspection), which is currently only available for Linux. However, most generated code works on other platforms.

## Status

Most of libgirepository is wrapped.
This allows information like lists of structs, methods, and functions to be extracted, as well as argument types, struct fields, etc.
Using this information, GI.jl produces Julia code.

## Generated code

Code generated by GI.jl currently requires [Gtk4.jl](https://github.com/JuliaGtk/Gtk4.jl).
In the future the GLib submodule of that package might be split off, and then
that could become the base requirement.

Below are a few details about the output.

### Constants, enums, and flags

Constant names are the same as in the C library but with the namespace removed.
So for example the C constant `G_PRIORITY_DEFAULT` becomes `PRIORITY_DEFAULT`.

Enums and flags are exported as [Cenum's](https://github.com/JuliaInterop/CEnum.jl)
and [BitFlags](https://github.com/jmert/BitFlags.jl), respectively. The name is
of the form EnumName_INSTANCE_NAME. So for example `G_SIGNAL_FLAGS_RUN_LAST`
becomes `SignalFlags_RUN_LAST`.

Constants, enums, and flags code is typically exported in a file "lib_consts" in a "src/gen" directory for a package to include.

### GObjects, GInterfaces, and GBoxed types

GObject and GInterface types are named as in Gtk.jl, with the namespace
included in the type name (for example `PangoLayout` or `GtkWindow`). This differs
from python bindings.

Properties are exported as Julia properties and can be accessed and set using
`my_object.property_name`. Alternatively the functions `get_gtk_property` or
`set_gtk_property!` can be used just like in Gtk.jl.

GBoxed types are named the same way as objects and interfaces. For non-opaque structs, a struct is defined with the same name, but preceded by an underscore. So for example, the pointer type is `GtkTreeIter`, and the struct is `_GtkTreeIter`.

Struct definitions are typically exported in a file "lib_structs" in a "src/gen" directory for a package to include.

### Constructors

Constructors for GObjects and structs are defined with a type name prefix.

### Methods

Methods of objects, interfaces, and structs are exported without the namespace
and, for C methods, the object/interface/struct name. So for example `pango_layout_get_extents`
becomes `get_extents`. Functions not associated with particular objects, interfaces, or structs are
exported with the namespace removed.

Arguments of C functions that are outputs are converted to returned outputs. When there
is a return value as well as argument outputs, the Julia method returns a tuple of the
outputs. For array inputs, the length parameter in the C function is removed for
Julia methods. Similarly, for array outputs, a length parameter output is
omitted in the Julia output. GError outputs are converted to throws. When pointer
inputs can optionally be NULL, the Julia methods accept nothing as the argument.
When outputs are NULL, the Julia methods output nothing.

Object and struct methods are typically exported in a file "lib_methods" in a "src/gen" directory and packages typically include them in a "G_" submodule.
Functions not associated with objects or structs are typically exported in a file "lib_functions".
