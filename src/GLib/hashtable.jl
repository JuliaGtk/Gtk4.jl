mutable struct GHashTable <: GBoxed
    handle::Ptr{GHashTable}
    (GLib.g_type(::Type{T}) where T <: GHashTable) = begin
            ccall((:g_hash_table_get_type, libgobject), GType, ())
        end
    function GHashTable(ref::Ptr{GHashTable}, own::Bool = false)
        x = new(ref)
        if own
            finalizer((x::GHashTable->begin
                        gtype = ccall((:g_hash_table_get_type, libgobject), GType, ())
                        ccall((:g_boxed_free, libgobject), Nothing, (GType, Ptr{GHashTable}), gtype, x.handle)
                    end), x)
        end
        x
    end
end
