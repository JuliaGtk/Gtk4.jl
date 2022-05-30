module GI
    using Glib_jll
    using MacroTools, CEnum, BitFlags

    include("GLib/GLib.jl")
    using .GLib
    import Glib_jll: libgobject, libglib
    import .GLib:
      unsafe_convert,
      AbstractStringLike, bytestring

    import Base: convert, cconvert, show, length, getindex, setindex!, uppercase, unsafe_convert
    using Libdl

    uppercase(s::Symbol) = Symbol(uppercase(string(s)))

    export GINamespace
    export const_expr
    export extract_type

    libgi = "libgirepository-1.0"

    global const libgi_version = VersionNumber(
      ccall((:gi_get_major_version, libgi), Cint, ()),
      ccall((:gi_get_minor_version, libgi), Cint, ()),
      ccall((:gi_get_micro_version, libgi), Cint, ()))


    include("girepo.jl")
    include("giimport.jl")
    include("giexport.jl")
end
