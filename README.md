# Julia interface to GTK version 4

[![CI](https://github.com/JuliaGtk/Gtk4.jl/workflows/CI/badge.svg)](https://github.com/JuliaGtk/Gtk4.jl/actions?query=workflow%3ACI)

GUI building using the [GTK](https://www.gtk.org) library, version 4. For a mature Julia package that supports GTK version 3, see [Gtk.jl](https://github.com/JuliaGraphics/Gtk.jl).

This package builds on Gtk.jl but uses GObject introspection to support more of the functionality of the GTK library and its dependencies. GObject introspection for Julia is implemented using [GI.jl](https://github.com/JuliaGtk/Gtk4.jl/tree/main/GI), which is also hosted in this repository.

Complete GTK documentation is available at [https://www.gtk.org/docs](https://www.gtk.org/docs). Documentation for this package exists but isn't online yet. See the `docs` subdirectory for now.

## CURRENT STATUS
Works OK on Linux (64 bit), but not recommended on Mac or Windows at this time. It might work for you but be prepared for trouble. Definitely not working on 32 bit systems because of a problem with how we do GObject introspection.

Most of the code for GLib support (`GType`, `GValue`, `GObject`, etc.) was copied with minor changes from [Gtk.jl](https://github.com/JuliaGraphics/Gtk.jl). This includes integration of the GLib main loop with Julia's main loop.
