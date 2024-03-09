struct GArray <: GBoxed
    data::Ptr{UInt8}
    len::UInt32
end

struct _GByteArray
    data::Ptr{UInt8}
    len::UInt32
end

mutable struct GByteArray <: GBoxed
    handle::Ptr{GByteArray}
    begin
        (GLib.g_type(::Type{T}) where T <: GByteArray) = begin
                ccall(("g_byte_array_get_type", libgobject), GType, ())
            end
        function GByteArray(ref::Ptr{GByteArray}, own::Bool = false)
            #println("constructing ", :GByteArray, " ", own)
            x = new(ref)
            if own
                finalizer((x::GByteArray->begin
                            gtype = ccall((:g_byte_array_get_type, libgobject), GType, ())
                            ccall((:g_boxed_free, libgobject), Nothing, (GType, Ptr{GByteArray}), gtype, x.handle)
                            #@async println("finalized ", GByteArray)
                        end), x)
            end
            x
        end
    end
end

function get_length(arr::GByteArray)
    s=unsafe_load(Ptr{_GByteArray}(arr.handle))
    s.len
end

function get_data(arr::GByteArray)
    s=unsafe_load(Ptr{_GByteArray}(arr.handle))
    s.data
end

struct GPtrArray <: GBoxed
    pdata::Ptr{Nothing}
    len::UInt32
end

# GBytes

function GBytes(data::AbstractArray)
    ptr = ccall((:g_bytes_new, libglib), Ptr{GBytes}, (Ptr{Nothing}, Csize_t), data, sizeof(data))
    convert(GBytes, ptr, true)
end
