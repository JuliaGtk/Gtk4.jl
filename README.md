# Julia interface to GTK version 4

[![CI](https://github.com/JuliaGtk/Gtk4.jl/workflows/CI/badge.svg)](https://github.com/JuliaGtk/Gtk4.jl/actions?query=workflow%3ACI)
[![codecov.io](https://codecov.io/github/JuliaGtk/Gtk4.jl/coverage.svg?branch=main)](https://app.codecov.io/gh/JuliaGtk/Gtk4.jl)
[![](https://img.shields.io/badge/docs-main-blue.svg)](https://juliagtk.github.io/Gtk4.jl/dev/)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://juliahub.com/docs/Gtk4)


GUI building using the [GTK](https://www.gtk.org) library, version 4. For a mature Julia package that supports GTK version 3, see [Gtk.jl](https://github.com/JuliaGraphics/Gtk.jl). **Note that Gtk.jl and Gtk4.jl cannot be imported in the same Julia session.**

This package builds on Gtk.jl but uses GObject introspection to support more of the functionality of the GTK library and its dependencies. GObject introspection for Julia is implemented using [GI.jl](https://github.com/JuliaGtk/Gtk4.jl/tree/main/GI), which is also hosted in this repository.

Most of the code for GLib support (`GType`, `GValue`, `GObject`, etc.) was copied with minor changes from [Gtk.jl](https://github.com/JuliaGraphics/Gtk.jl). This includes integration of the GLib main loop with Julia's event loop.

Documentation for the master branch version of this package can be found [here](https://juliagtk.github.io/Gtk4.jl/dev/). Complete GTK documentation is available at [https://www.gtk.org/docs](https://www.gtk.org/docs).

## Current status
Based on limited data, Gtk4.jl works about as well as Gtk.jl. Notably, it does not cause REPL lag on Windows the way that Gtk.jl does.

For auto-generated code, Gtk4.jl relies on GObject introspection data generated on a Linux x86_64 machine, which may result in code that crashes on 32 bit computers. This seems to affect mostly obscure parts of GLib that are unlikely to be useful to Julia users, but 32 bit users should be aware of this.

## Enabling GTK4's EGL backend (Linux)
On Wayland, a Cairo-based fallback backend will be used unless you tell `libglvnd_jll` where to find libEGL. This can be done by setting the environment variable __EGL_VENDOR_LIBRARY_DIRS. See [here](https://gitlab.freedesktop.org/glvnd/libglvnd/-/blob/master/src/EGL/icd_enumeration.md) for details.

For convenience, in Gtk4.jl this can be set as a preference for a particular Julia environment using Preferences.jl:
```julia
using Gtk4
Gtk4.set_EGL_vendorlib_dirs("/usr/share/glvnd/egl_vendor.d")
[ Info: Setting will take effect after restarting Julia.
```
where "/usr/share/glvnd/egl_vendor.d" is a typical location for Mesa's libEGL (this should be modified if it's somewhere else on your distribution). Other vendor-provided libraries may be in other locations, and a colon-separated list of directories can be used for that situation. **Note that this has only been tested for the Mesa-provided libEGL on Fedora and Ubuntu.**