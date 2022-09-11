module GI
    using Glib_jll, gobject_introspection_jll
    using MacroTools, CEnum, BitFlags, EzXML

    include("GLibBase/GLibBase.jl")

    import .GLibBase as GLib
    import .GLibBase:
      unsafe_convert, GError, GObject, GType, GArray, GPtrArray, GByteArray,
      GHashTable, GList, GInterface, GBoxed, AbstractStringLike, bytestring,
      gtkdoc_const_url, gtkdoc_enum_url, gtkdoc_flags_url, gtkdoc_method_url,
      gtkdoc_func_url, gtkdoc_struc_url, gtkdoc_object_url

    import Base: convert, cconvert, show, length, getindex, setindex!, uppercase, unsafe_convert
    using Libdl

    uppercase(s::Symbol) = Symbol(uppercase(string(s)))

    export GINamespace
    export const_expr
    export extract_type

    libgi = gobject_introspection_jll.libgirepository

    global const libgi_version = VersionNumber(
      ccall((:gi_get_major_version, libgi), Cint, ()),
      ccall((:gi_get_minor_version, libgi), Cint, ()),
      ccall((:gi_get_micro_version, libgi), Cint, ()))


    include("girepo.jl")
    include("giimport.jl")
    include("giexport.jl")
    include("gidocs.jl")
end
