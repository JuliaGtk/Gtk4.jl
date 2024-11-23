module GI
    using Glib_jll
    using MacroTools, CEnum, BitFlags, EzXML

    include("GLibBase/GLibBase.jl")

    import .GLibBase as GLib
    import .GLibBase:
      unsafe_convert, GError, GObject, GType, GArray, GPtrArray, GByteArray, GTypeInstance,
      GHashTable, GList, GInterface, GBoxed, AbstractStringLike, bytestring,
      gtkdoc_const_url, gtkdoc_enum_url, gtkdoc_flags_url, gtkdoc_method_url,
      gtkdoc_func_url, gtkdoc_struc_url, gtkdoc_object_url

    import Base: convert, cconvert, show, length, getindex, setindex!, uppercase, unsafe_convert
    using Libdl

    symuppercase(s::Symbol) = Symbol(uppercase(string(s)))
    symuppercase(s::AbstractString) = Symbol(uppercase(s))

    export GINamespace
    export const_expr
    export extract_type

    libgi = Glib_jll.libgirepository

    include("girepo.jl")
    include("giimport.jl")
    include("giexport.jl")
    include("gidocs.jl")
    
    function __init__()
        global repo = GIRepository()
    end
end
