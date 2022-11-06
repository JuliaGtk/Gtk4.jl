This is a trivial example of a `Gtk4.jl` application that can be compiled using [PackageCompiler.jl](https://github.com/JuliaLang/PackageCompiler.jl). To
compile, run the following in this directory:

```
using PackageCompiler

create_app("","target")
```

This has not been tested much, and it appears that the accessor methods don't work when using `PackageCompiler`.
