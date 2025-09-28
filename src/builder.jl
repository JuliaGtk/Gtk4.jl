@doc """
    GtkBuilder(; kwargs...)
    GtkBuilder(filename::AbstractString; kwargs...)
    GtkBuilder(string::AbstractString, _length::Integer; kwargs...)

Create a `GtkBuilder` object. If `filename` is given (the constructor with a
single string argument), XML describing the user interface will be read from a
file. If `string` and `length` are given (the constructor with a string and an
integer), XML will be read from a string of a certain `length`. If `length` is
-1 the full string will be used.

See the [GTK docs](https://docs.gtk.org/gtk4/class.Builder.html).
""" GtkBuilder

function push!(builder::GtkBuilder; buffer = nothing, filename = nothing)
    if buffer !== nothing
        if Sys.WORD_SIZE == 64  # this method takes gssize as the length of the string so crashes on 32 bit
            G_.add_from_string(builder, buffer, -1)
        else
            err = err_buf()
            ret = ccall(("gtk_builder_add_from_string", libgtk4), Cint, (Ptr{GObject}, Cstring, Cssize_t, Ptr{Ptr{GError}}), instance, _buffer, _length, err)
            check_err(err)
        end
    elseif filename !== nothing
        G_.add_from_file(builder, filename)
    end
    return builder
end

start_(builder::GtkBuilder) = glist_iter(ccall((:gtk_builder_get_objects, libgtk4), Ptr{_GSList{GObject}}, (Ptr{GObject},), builder))
iterate(builder::GtkBuilder, list=start_(builder)) = iterate(list[1], list)

length(builder::GtkBuilder) = length(start_(builder)[1])
getindex(builder::GtkBuilder, i::Integer) = convert(GObject, G_.get_objects(builder)[i], false)

getindex(builder::GtkBuilder, widgetId::String) = G_.get_object(builder, widgetId)

function load_builder(b::GtkBuilder,cm::Module)
    objs=[obj for obj in b]
    for obj in objs
        gt = GLib.G_OBJECT_CLASS_TYPE(obj)
        if GLib.g_isa(gt, GLib.g_type_from_name(:GtkBuildable)) # not all classes implement GtkBuildable, e.g. GtkAdjustment
             name = ccall((:gtk_buildable_get_buildable_id, libgtk4), Ptr{UInt8}, (Ptr{GObject},), obj)
             if name != C_NULL
                 name = GLib.bytestring(name)
                 # name begins with three underscores if id isn't set in glade
                 if !startswith(name,"___")
                     sname = Symbol(name)
                     if !Base.isidentifier(sname)
                         @warn("$sname is not a valid variable name.")
                         continue
                     end
                     Core.eval(cm,:($sname = $obj))
                 end
            end
        end
    end
end

# Below is experimental

"""
    @load_builder(b::GtkBuilder)

Loads all GtkBuildable objects from a GtkBuilder object and assigns them to Julia
variables in the current scope. GtkBuilder ID's are mapped onto Julia variable
names.
"""
macro load_builder(b)
    esc(:(Gtk4.load_builder($b,$__module__)))
end

mutable struct _GtkBuilderScopeInterface
    g_iface::_GTypeInterface
    get_type_from_name::Ptr{Cvoid}
    get_type_from_function::Ptr{Cvoid}
    create_closure::Ptr{Cvoid}
end

function _jbuilderscope_create_closure(self::Ptr{GObject}, builder_ptr::Ptr{GObject}, function_name::Cstring, flags::Cint, object_ptr::Ptr{GObject}, err::Ptr{GError})
    scope = convert(JuliaBuilderScope, self)
    builder = convert(GtkBuilder, builder_ptr)
    object = if object_ptr == C_NULL
        G_.get_current_object(builder)
    else
        convert(GObject, object_ptr)
    end
    name=GLib.bytestring(function_name)
    f = getfield(scope.mod, Symbol(name))
    closure = if object !== nothing
        GLib.create_closure(f, object)
    else
        GLib.create_closure(f)
    end
    return closure.handle
end

function _jbuilderscope_interface_init(interface::Ptr{_GtkBuilderScopeInterface}, user_data)
    interf = unsafe_load(interface)
    interf.create_closure = @cfunction(_jbuilderscope_create_closure, Ptr{Nothing}, (Ptr{GObject}, Ptr{GObject}, Cstring, Cint, Ptr{GObject}, Ptr{GError}))
    unsafe_store!(interface, interf)
    nothing
end

_builder_scope_class_init(class::Ptr{_GObjectClass}, user_data) = nothing

mutable struct JuliaBuilderScope <: GObject
    handle::Ptr{GObject}
    mod::Module
end

function GLib.g_type(::Type{T}) where T <: JuliaBuilderScope
    gt = GLib.g_type_from_name(:JuliaBuilderScope)
    if gt > 0
        return gt
    else
        object_class_init_cfunc = @cfunction(_builder_scope_class_init, Cvoid, (Ptr{_GObjectClass}, Ptr{Cvoid}))
        subtype = GLib.register_subtype(GObject, :JuliaBuilderScope, object_class_init_cfunc)
        interface_init_cfunc = @cfunction(_jbuilderscope_interface_init, Cvoid, (Ptr{_GtkBuilderScopeInterface}, Ptr{Cvoid}))
        GLib.add_interface(subtype, GtkBuilderScope, interface_init_cfunc)
        return subtype
    end
end

JuliaBuilderScope(mod) = GLib.gobject_new(JuliaBuilderScope, mod)

"""
    GtkBuilder(mod::Module)

Create a `GtkBuilder` object that will attempt to connect signal handlers using
functions in a Julia module `mod`.
"""
function GtkBuilder(mod::Module)
    b = GtkBuilder()
    j = Gtk4.JuliaBuilderScope(mod)
    Gtk4.G_.set_scope(b, GtkBuilderScope(j))
    b
end
