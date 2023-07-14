function setproperties!(obj::GObject; kwargs...)
    for (kw, val) = kwargs
        set_gtk_property!(obj, kw, val)
    end
end

# converts the string output by `g_value_get_string` to Julia equivalent
function gvalue_string_convert(str)
    value = (str == C_NULL ? "nothing" : GLib.bytestring(str))
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
    v = gvalue(String)
    first = true
    for i = 1:n[]
        param = unsafe_load(unsafe_load(props, i))
        if !first
            print(io, ", ")
        else
            first = false
        end
        print(io, GLib.bytestring(param.name))
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
    print(io, ')')
    ccall((:g_value_unset, libgobject), Ptr{Nothing}, (Ptr{GValue},), v)
end

"""
    propertyinfo(w::GObject, name)

Prints information about a property of the GObject `w`, including a
brief description, its type, its default value, and its current value.
"""
function propertyinfo(w::GObject, name::AbstractString)
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
    printstyled("Description: "; bold = true)
    println(bytestring(blurb))

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
