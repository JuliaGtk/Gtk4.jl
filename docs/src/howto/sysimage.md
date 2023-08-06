# Gtk4 in a sysimage

Note that if Gtk4 is included in a sysimage using [PackageCompiler.jl](https://github.com/JuliaLang/PackageCompiler.jl), the main loop will not be started automatically when calling `using Gtk4` **even in an interactive Julia session**. You will have to call `GLib.start_main_loop()` before windows will appear.

