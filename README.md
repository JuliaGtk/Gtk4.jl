# Julia interface to GTK version 4

[![CI](https://github.com/JuliaGtk/Gtk4.jl/workflows/CI/badge.svg)](https://github.com/JuliaGtk/Gtk4.jl/actions?query=workflow%3ACI)
[![codecov.io](https://codecov.io/github/JuliaGtk/Gtk4.jl/coverage.svg?branch=main)](https://app.codecov.io/gh/JuliaGtk/Gtk4.jl)
[![](https://img.shields.io/badge/docs-main-blue.svg)](https://juliagtk.github.io/Gtk4.jl/dev/)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://juliahub.com/docs/Gtk4)


GUI building using [GTK](https://www.gtk.org) version 4. See [Gtk.jl](https://github.com/JuliaGraphics/Gtk.jl) for a Julia package that supports GTK version 3. **Note that Gtk.jl and Gtk4.jl cannot be imported in the same Julia session.**

This package builds on Gtk.jl but uses GObject introspection to support more of the functionality of the GTK library and its dependencies. GObject introspection for Julia is implemented using [GI.jl](https://github.com/JuliaGtk/Gtk4.jl/tree/main/GI), which is also hosted in this repository.

Most of the code for GLib support (`GType`, `GValue`, `GObject`, etc.) was copied with minor changes from [Gtk.jl](https://github.com/JuliaGraphics/Gtk.jl). This includes integration of the GLib main loop with Julia's event loop.

Documentation for the master branch version of this package can be found [here](https://juliagtk.github.io/Gtk4.jl/dev/). Example code can be found [here](https://github.com/JuliaGtk/Gtk4.jl/tree/main/examples). Complete GTK documentation is available at [https://www.gtk.org/docs](https://www.gtk.org/docs).

## Package scope and alternatives

This package is intended to be a relatively thin wrapper of the GTK library based largely on GObject introspection, analogous to [PyGObject](https://pypi.org/project/PyGObject/). Using it beyond simple widgets requires some knowledge of the GTK API (the Gtk4.jl [documentation](https://juliagtk.github.io/Gtk4.jl/dev/) covers a small fraction of the API available through introspection). It is also very possible to crash or freeze Julia if you're not careful.

Those seeking a more user friendly, well documented, curated GUI building experience based on GTK should consider using [Mousetrap](https://github.com/Clemapfel/mousetrap.jl). Other popular packages for creating desktop GUI interfaces include [QML.jl](https://github.com/JuliaGraphics/QML.jl), [Blink.jl](https://github.com/JuliaGizmos/Blink.jl), [Electron.jl](https://github.com/davidanthoff/Electron.jl), and [CImGui.jl](https://github.com/Gnimuc/CImGui.jl).

## Related packages

Other registered packages extend the functionality of Gtk4.jl:
- [GtkObservables.jl](https://github.com/JuliaGizmos/GtkObservables.jl): provides integration with [Observables.jl](https://github.com/JuliaGizmos/Observables.jl). This package can simplify making interactive GUI's with Gtk4.jl.
- [Gtk4Makie.jl](https://github.com/JuliaGtk/Gtk4Makie.jl): provides integration with the popular plotting package [Makie.jl](https://github.com/MakieOrg/Makie.jl), specifically its interactive, high performance GLMakie backend.

A port of [ProfileView](https://github.com/timholy/ProfileView.jl) based on Gtk4 is available.
The registered version of ProfileView.jl uses Gtk.jl, which is incompatible with Gtk4.
To use the Gtk4 port, enter `add https://github.com/jwahlstrand/ProfileView.jl#gtk4` in Julia's package mode.

## Current status
For auto-generated code, Gtk4.jl relies on GObject introspection data generated on a Linux x86_64 machine, which may result in code that crashes on 32 bit computers. This seems to affect mostly obscure parts of GLib that are unlikely to be useful to Julia users, but 32 bit users should be aware of this.

Note that this package uses binaries for the GTK library and its dependencies that are built and packaged using [BinaryBuilder.jl](https://github.com/JuliaPackaging/BinaryBuilder.jl). On Linux it does **not** use the binaries that are packaged with your distribution. The build scripts for the binaries used by Gtk4.jl, including the library versions currently being used, can be found by perusing [Yggdrasil.jl](https://github.com/JuliaPackaging/Yggdrasil.jl).

### Known incompatibilities

Gtk4.jl is known to interfere with some other packages, including [PyPlot.jl](https://github.com/JuliaPy/PyPlot.jl) and [GLMakie.jl](https://github.com/MakieOrg/Makie.jl). To use Gtk4 based packages with Makie, you can use [Gtk4Makie.jl](https://github.com/JuliaGtk/Gtk4Makie.jl).

## Enabling GTK4's EGL backend (Linux)
On Wayland, a Cairo-based fallback backend will be used unless you tell `libglvnd_jll` where to find libEGL. This can be done by setting the environment variable __EGL_VENDOR_LIBRARY_DIRS. See [here](https://gitlab.freedesktop.org/glvnd/libglvnd/-/blob/master/src/EGL/icd_enumeration.md) for details.

For convenience, in Gtk4.jl this can be set as a preference for a particular Julia environment using Preferences.jl:
```julia
using Gtk4
Gtk4.set_EGL_vendorlib_dirs("/usr/share/glvnd/egl_vendor.d")
[ Info: Setting will take effect after restarting Julia.
```
where "/usr/share/glvnd/egl_vendor.d" is a typical location for Mesa's libEGL (this should be modified if it's somewhere else on your distribution). Other vendor-provided libraries may be in other locations, and a colon-separated list of directories can be used for that situation. **Note that this has only been tested for the Mesa-provided libEGL on Fedora and Ubuntu.**

