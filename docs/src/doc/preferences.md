# Preference Settings

Here is a list of preferences for Gtk4 that can be set using Preferences.jl.

## EGL directories (Linux & Wayland)

GTK4 has a few different rendering backends, and by default on Linux it uses one based on OpenGL. Gtk4.jl uses JLL based libraries rather than the ones that come with your Linux distribution, and on Wayland, unfortunately, unless you tell `libglvnd_jll` where to find libEGL, it will be unable to find an OpenGL provider. As a result, on Wayland a Cairo-based fallback backend will be used. This may work fine for you, but it means that `GtkGLArea` will not work. We can tell `libglvnd_jll` where to find libEGL by setting the environment variable `__EGL_VENDOR_LIBRARY_DIRS`. See [here](https://gitlab.freedesktop.org/glvnd/libglvnd/-/blob/master/src/EGL/icd_enumeration.md) for details.

You can point `libglvnd_jll` to a libEGL location using the preference `"EGL_vendorlib_dirs"`:
```julia
using Gtk4
Gtk4.set_EGL_vendorlib_dirs("/usr/share/glvnd/egl_vendor.d")
[ Info: Setting will take effect after restarting Julia.
```
where "/usr/share/glvnd/egl_vendor.d" is a typical location for Mesa's libEGL (this should be modified if it's somewhere else on your distribution). Other vendor-provided libraries may be in other locations, and a colon-separated list of directories can be used for that situation. **Note that this has only been tested for the Mesa-provided libEGL on Fedora and Ubuntu.**

## UV loop integration

GTK relies on an event loop (provided by GLib) to process and handle mouse and keyboard events, while Julia relies on its own event loop (provided by libuv) for IO, timers, etc. Interactions between these event loops can cause REPL lag and can interfere with multithreading performance. Explicit integration of the two loops by creating a libuv event source in the GLib main loop is currently [disabled](https://github.com/JuliaGraphics/Gtk.jl/pull/630) because it caused [slowdowns in multithreaded code](https://github.com/JuliaGraphics/Gtk.jl/issues/503). On some Macs, unfortunately, [REPL lag](https://github.com/JuliaGtk/Gtk4.jl/issues/23) occurs without this explicit integration (explicit in the sense that libuv can insert events in the GLib main loop through its own GSource).

By default, explicit GLib loop integration is only turned on on Macs in an interactive session. You can override this using the preference `"uv_loop_integration"`. If it's set to "enabled", the libuv GSource will be created. If it's set to "disabled", the libuv GSource will not be created, even on Macs in an interactive session. The setting "auto" uses the default behavior. The functions `GLib.set_uv_loop_integration` and `GLib.get_uv_loop_integration` can be used to set and get the preference.
