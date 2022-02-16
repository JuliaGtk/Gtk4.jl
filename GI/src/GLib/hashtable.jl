mutable struct GHashTable <: GBoxed
    handle::Ptr{GHashTable}
    begin
        (GLib.g_type(::Type{T}) where T <: GHashTable) = begin
                ccall((:g_hash_table_get_type, libgobject), GType, ())
            end
        function GHashTable(ref::Ptr{GHashTable}, own::Bool = false)
            gtype = ccall((:g_hash_table_get_type, libgobject), GType, ())
            own || ccall((:g_boxed_copy, libgobject), Nothing, (GType, Ptr{GHashTable}), gtype, ref)
            x = new(ref)
            finalizer((x::GHashTable->begin
                        ccall((:g_boxed_free, libgobject), Nothing, (GType, Ptr{GHashTable}), gtype, x.handle)
                    end), x)
        end
    end
end
