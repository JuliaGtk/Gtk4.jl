# Misc. libgio functions

GFile(p::AbstractString) = GFile(G_.new_for_path(p))
Base.ispath(f::GFile) = G_.query_exists(f,nothing)
Base.isdir(f::GFile) = (G_.query_file_type(f,FileQueryInfoFlags_NONE,nothing)==FileType_DIRECTORY)
Base.isfile(f::GFile) = (G_.query_file_type(f,FileQueryInfoFlags_NONE,nothing)==FileType_REGULAR)
Base.islink(f::GFile) = (G_.query_file_type(f,FileQueryInfoFlags_NONE,nothing)==FileType_SYMBOLIC_LINK)
Base.basename(f::GFile) = G_.get_basename(f)
path(f::GFile) = G_.get_path(f)

query_info(f::GFile, attributes="*", flags=FileQueryInfoFlags_NONE) = G_.query_info(f,attributes,flags,nothing)
Base.keys(fi::GFileInfo) = G_.list_attributes(fi,nothing)
function getindex(fi::GFileInfo,att::AbstractString)
    typ = G_.get_attribute_type(fi,att)
    if typ == FileAttributeType_STRING
        return G_.get_attribute_string(fi,att)
    elseif typ == FileAttributeType_BYTE_STRING
        return G_.get_attribute_byte_string(fi,att)
    elseif typ == FileAttributeType_BOOLEAN
        return G_.get_attribute_boolean(fi,att)
    elseif typ == FileAttributeType_UINT32
        return G_.get_attribute_uint32(fi,att)
    elseif typ == FileAttributeType_INT32
        return G_.get_attribute_int32(fi,att)
    elseif typ == FileAttributeType_UINT64
        return G_.get_attribute_uint64(fi,att)
    elseif typ == FileAttributeType_INT64
        return G_.get_attribute_int64(fi,att)
    elseif typ == FileAttributeType_OBJECT
        return G_.get_attribute_object(fi,att)
    else
        error("unsupported FileAttributeType: $typ")
    end
end

cancel(c::GCancellable) = G_.cancel(c)
iscancelled(c::GCancellable) = G_.is_cancelled(c)

"""
    cancel_after_delay(timeout)->GCancellable

Creates and returns a `GCancellable` and after `timeout` seconds, cancels it.
"""
function cancel_after_delay(timeout)
    cancellable = GCancellable()
    if timeout > 0
        Timer(timeout) do timer
            cancel(cancellable)
        end
    end
    cancellable
end

mutable struct _GActionInterface
    g_iface::_GTypeInterface
    get_name::Ptr{Cvoid}
    get_parameter_type::Ptr{Cvoid}
    get_state_type::Ptr{Cvoid}
    get_state_hint::Ptr{Cvoid}
    get_enabled::Ptr{Cvoid}
    get_state::Ptr{Cvoid}
    change_state::Ptr{Cvoid}
    activate::Ptr{Cvoid}
end

