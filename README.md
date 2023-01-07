# Julia interface to GTK version 4

[![CI](https://github.com/JuliaGtk/Gtk4.jl/workflows/CI/badge.svg)](https://github.com/JuliaGtk/Gtk4.jl/actions?query=workflow%3ACI)
[![codecov.io](https://codecov.io/github/JuliaGtk/Gtk4.jl/coverage.svg?branch=main)](https://codecov.io/github/JuliaGtk/Gtk4.jl?branch=main)
[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://juliagtk.github.io/Gtk4.jl/dev/)

GUI building using the [GTK](https://www.gtk.org) library, version 4. For a mature Julia package that supports GTK version 3, see [Gtk.jl](https://github.com/JuliaGraphics/Gtk.jl). **Note that Gtk.jl and Gtk4.jl cannot be imported in the same Julia session.**

This package builds on Gtk.jl but uses GObject introspection to support more of the functionality of the GTK library and its dependencies. GObject introspection for Julia is implemented using [GI.jl](https://github.com/JuliaGtk/Gtk4.jl/tree/main/GI), which is also hosted in this repository.

Most of the code for GLib support (`GType`, `GValue`, `GObject`, etc.) was copied with minor changes from [Gtk.jl](https://github.com/JuliaGraphics/Gtk.jl). This includes integration of the GLib main loop with Julia's event loop.

Documentation for this package can be found [here](https://juliagtk.github.io/Gtk4.jl/dev/). Complete GTK documentation is available at [https://www.gtk.org/docs](https://www.gtk.org/docs).

## CURRENT STATUS
With a recent update of GTK4_jll to 4.6.9, Gtk4.jl is less buggy on Mac and Windows than before. It is not recommended on 32 bit systems because of a deficiency with how GObject introspection is done here.
