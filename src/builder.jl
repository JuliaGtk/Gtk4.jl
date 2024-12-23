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
            error("this method doesn't work on 32 bit systems, use a ccall")
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
        gt = GObjects.G_OBJECT_CLASS_TYPE(obj)
        if GObjects.g_isa(gt, GObjects.g_type_from_name(:GtkBuildable)) # not all classes implement GtkBuildable, e.g. GtkAdjustment
             name = ccall((:gtk_buildable_get_buildable_id, libgtk4), Ptr{UInt8}, (Ptr{GObject},), obj)
             if name != C_NULL
                 name = GObjects.bytestring(name)
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

"""
    @load_builder(b::GtkBuilder)

Loads all GtkBuildable objects from a GtkBuilder object and assigns them to Julia
variables in the current scope. GtkBuilder ID's are mapped onto Julia variable
names.
"""
macro load_builder(b)
    esc(:(Gtk4.load_builder($b,$__module__)))
end
