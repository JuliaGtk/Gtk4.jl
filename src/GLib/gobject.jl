"""
    setproperties!(obj::GObject; kwargs...)

Set many `GObject` properties at once using keyword arguments. For example
for a `GtkWindow`, `setproperties!(win; title="New title", visible=true)`.
"""
function setproperties!(obj::GObject; kwargs...)
    for (kw, val) = kwargs
        set_gtk_property!(obj, kw, val)
    end
end

# converts the string output by `g_value_get_string` to Julia equivalent
function gvalue_string_convert(str)
    value = (str == C_NULL ? "nothing" : bytestring(str))
    if value == "TRUE"
        value = "true"
    elseif value == "FALSE"
        value = "false"
    end
    value
end

function show(io::IO, w::GObject)
    DEPRECATED = 0x80000000
    print(io, typeof(w), '(')
    if unsafe_convert(Ptr{GObject}, w) == C_NULL
        print(io, "<NULL>)")
        return
    end
    n = Ref{Cuint}()
    props = ccall((:g_object_class_list_properties, libgobject), Ptr{Ptr{GParamSpec}},
        (Ptr{Nothing}, Ptr{Cuint}), G_OBJECT_GET_CLASS(w), n)
    if get(io, :compact, false)::Bool
        print(io, getfield(w,:handle)) # show pointer
    else # show properties
        v = gvalue(String)
        first = true
        for i = 1:n[]
            param = unsafe_load(unsafe_load(props, i))
            if !first
                print(io, ", ")
            else
                first = false
            end
            print(io, bytestring(param.name))
            if (ParamFlags(param.flags) & ParamFlags_READABLE) != 0 &&
                (param.flags & DEPRECATED) == 0 &&
                (ccall((:g_value_type_transformable, libgobject), Cint,
                       (Int, Int), param.value_type, g_type(AbstractString)) != 0)
                ccall((:g_object_get_property, libgobject), Nothing,
                      (Ptr{GObject}, Ptr{UInt8}, Ptr{GValue}), w, param.name, v)
                str = ccall((:g_value_get_string, libgobject), Ptr{UInt8}, (Ptr{GValue},), v)
                value = gvalue_string_convert(str)
                if param.value_type == g_type(AbstractString) && str != C_NULL
                    print(io, "=\"", value, '"')
                else
                    print(io, '=', value)
                end
            end
        end
        ccall((:g_value_unset, libgobject), Ptr{Nothing}, (Ptr{GValue},), v)
    end
    print(io, ')')
    nothing
end

"""
    propertyinfo(w::GObject, name)

Prints information about a property of the GObject `w`, including a
brief description, its type, its default value, and its current value.
"""
function propertyinfo(@nospecialize(w::GObject), name::AbstractString)
    p = ccall((:g_object_class_find_property, libgobject), Ptr{GParamSpec}, (Ptr{Nothing}, Ptr{UInt8}), G_OBJECT_GET_CLASS(w), name)
    if p == C_NULL
        error("No property with that name")
        return
    end
    param = unsafe_load(p)
    printstyled("Name: "; bold = true)
    println(name)
    printstyled("GType name: "; bold = true)
    println(g_type_name(param.value_type))
    printstyled("Flags: "; bold = true)
    if (ParamFlags(param.flags) & ParamFlags_READABLE) != 0
        print("Readable  ")
    end
    if (ParamFlags(param.flags) & ParamFlags_WRITABLE) != 0
        print("Writable  ")
    end
    if (ParamFlags(param.flags) & ParamFlags_CONSTRUCT_ONLY) != 0
        print("Construct only  ")
    end
    if (ParamFlags(param.flags) & ParamFlags_EXPLICIT_NOTIFY) != 0
        print("Explicit notify  ")
    end
    print("\n")
    blurb = ccall((:g_param_spec_get_blurb, libgobject), Ptr{UInt8}, (Ptr{GParamSpec},), p)
    if blurb != C_NULL
        printstyled("Description: "; bold = true)
        println(bytestring(blurb))
    end

    if ccall((:g_value_type_transformable, libgobject), Cint,
        (Int, Int), param.value_type, g_type(AbstractString)) != 0
        p_default_value = ccall((:g_param_spec_get_default_value, libgobject), Ptr{GValue}, (Ptr{GParamSpec},), p)
        default_value = unsafe_load(p_default_value)
        str_value = gvalue(String)
        ccall((:g_value_transform, libgobject), Cint, (Ptr{GValue}, Ptr{GValue}), p_default_value, str_value)
        str = ccall((:g_value_get_string, libgobject), Ptr{UInt8}, (Ptr{GValue},), str_value)
        printstyled("Default value: "; bold = true)
        println(gvalue_string_convert(str))

        if (ParamFlags(param.flags) & ParamFlags_READABLE) == ParamFlags_READABLE
            ccall((:g_object_get_property, libgobject), Nothing,
                (Ptr{GObject}, Ptr{UInt8}, Ptr{GValue}), w, name, str_value)
                str = ccall((:g_value_get_string, libgobject), Ptr{UInt8}, (Ptr{GValue},), str_value)
                printstyled("Current value: "; bold = true)
                println(gvalue_string_convert(str))

                ccall((:g_value_unset, libgobject), Ptr{Nothing}, (Ptr{GValue},), str_value)
            end
     end
     nothing
end
propertyinfo(w::GObject,name::Symbol) = propertyinfo(w,string(name))

"""
    bind_property(source::GObject, source_property, target::GObject, target_property, flags = BindingFlags_DEFAULT)

Creates a binding between `source_property` on `source` and `target_property` on
`target`. When `source_property` is changed, `target_property` will be updated
to the same value. Returns a `GBinding` object that can be used to release the
binding using `unbind_property`.

See also [`unbind_property`](@ref).

Related GTK function: [`g_object_bind_property`](https://docs.gtk.org/gobject/method.Object.bind_property.html)
"""
bind_property(source::GObject, source_property, target::GObject, target_property, flags = BindingFlags_DEFAULT) =
    G_.bind_property(source, source_property, target, target_property, flags)

"""
    unbind_property(b::GBinding)

Releases a binding created by `bind_property`.

See also [`bind_property`](@ref).

Related GTK function: [`g_binding_unbind`](https://docs.gtk.org/gobject/method.Binding.unbind.html)
"""
unbind_property(b::GBinding) = G_.unbind(b)

## Below is experimental and unstable!

mutable struct _GObjectClass
    g_type_class::_GTypeClass
    construct_properties::Ptr{GLib._GSList{Ptr{Nothing}}}
    constructor::Ptr{Nothing}
    set_property::Ptr{Cvoid}
    get_property::Ptr{Cvoid}
    dispose::Ptr{Cvoid}
    finalize::Ptr{Cvoid}
    dispatch_properties_changed::Ptr{Cvoid}
    notify::Ptr{Cvoid}
    constructed::Ptr{Cvoid}
    flags::Csize_t
    n_construct_properties::Csize_t
    pspecs::Ptr{Nothing}
    n_pspecs::Csize_t
    pdummy1::Ptr{Nothing}
    pdummy2::Ptr{Nothing}
    pdummy3::Ptr{Nothing}
end

# Register a subtype of `T` with name `typename` and class init C function `object_class_init_cfunc`.
# The class init function should fill in the virtual functions necessary for the class and its ancestors.
function register_subtype(::Type{T}, typename::Symbol, object_class_init_cfunc) where T<:GObject
    base_gtype = g_type(T)
    tq=G_.type_query(base_gtype)
    typeinfo = _GTypeInfo(tq.class_size,
               C_NULL,   # base_init
               C_NULL,   # base_finalize
               object_class_init_cfunc,
               C_NULL,   # class_finalize
               C_NULL,   # class_data
               tq.instance_size,
               0,        # n_preallocs
               C_NULL,   # instance_init
               C_NULL)   # value_table
    G_.type_register_static(base_gtype,typename,Ref(typeinfo),TypeFlags_FINAL)
end

# Add an interface implementation to a type
function add_interface(subtype::GType, interface_type, interface_init_cfunc)
    interfaceinfo=_GInterfaceInfo(interface_init_cfunc,
                                  C_NULL,
                                  C_NULL)
    G_.type_add_interface_static(subtype, g_type(interface_type), Ref(interfaceinfo))
end

# Override a property (sometimes needed for interfaces or subtypes) of a `class`
# `property_id` is under your control but you have to be self-consistent
function override_property(class::Ptr{_GObjectClass}, property_id, name::AbstractString)
    ccall((:g_object_class_override_property, libgobject), Cvoid, (Ptr{_GObjectClass}, Cuint, Cstring), class, property_id, name)
end

# Asks GLib to make a new GObject
function gobject_new(juliatype, args...)
    gtype = g_type(juliatype)
    h=ccall(("g_object_new", libgobject), Ptr{GObject}, (UInt64, Ptr{Cvoid}), gtype, C_NULL)
    gobject_maybe_sink(h, false)
    gobject_ref(juliatype(h, args...))
end
