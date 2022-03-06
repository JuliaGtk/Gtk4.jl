
function GtkBuilder(; buffer = nothing, filename = nothing, resource = nothing)
    builder = G_.Builder_new()
    push!(builder, buffer = buffer, filename = filename, resource = resource)
    builder
end

function push!(builder::GtkBuilder; buffer = nothing, filename = nothing, resource = nothing)
    source_count = (buffer !== nothing) + (filename !== nothing) + (resource !== nothing)
    @assert(source_count == 1,
        "push!(GtkBuilder) must have exactly one buffer, filename, or resource argument")
    if buffer !== nothing
        return G_.add_from_string(builder, buffer, -1)
    elseif filename !== nothing
        return G_.add_from_file(builder, filename)
    elseif resource !== nothing
        return G_.add_from_resource(builder, resource)
    end
    return builder
end

#iterate(builder::GtkBuilder, list=start_(G_.get_objects(builder))) =
#   iterate(list[1], list)


#length(builder::GtkBuilder) = length(start_(builder)[1])
getindex(builder::GtkBuilder, i::Integer) = convert(GObject, G_.get_objects(builder)[i], false)

getindex(builder::GtkBuilder, widgetId::String) = G_.get_object(builder, widgetId)
