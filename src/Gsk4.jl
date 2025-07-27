function glib_ref(x::Ptr{GskRenderNode})
    ccall((:gsk_render_node_ref, libgtk4), Nothing, (Ptr{GskRenderNode},), x)
end
function glib_unref(x::Ptr{GskRenderNode})
    ccall((:gsk_render_node_unref, libgtk4), Nothing, (Ptr{GskRenderNode},), x)
end

Base.show(io::IO, t::GskTransform) = print(io,"GskTransform("*G_.to_string(t)*")")

## GskPath

build(b::GskPathBuilder) = G_.to_path(b)

