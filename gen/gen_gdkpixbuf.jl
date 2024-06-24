using GI

printstyled("Generating code for GdkPixbuf\n";bold=true)

ns = GINamespace(:GdkPixbuf,"2.0")
d = GI.read_gir(gdk_pixbuf_jll, ns)
path="../src/gen"

GI.export_consts!(ns, path, "gdkpixbuf", [:PixbufFormatFlags]; doc_prefix = "gdk-pixbuf", doc_xml = d, export_constants = false)

## structs

disguised = GI.read_disguised(d)
struct_skiplist=vcat(disguised,[:PixbufModule])

first_list=[:PixbufModulePattern]

obj_constructor_skiplist=[:new_from_resource,:new_with_mime_type,:new_from_resource_at_scale]

struct_skiplist = GI.export_struct_exprs!(ns,path, "gdkpixbuf", struct_skiplist, []; doc_xml = d, object_skiplist = obj_skiplist, object_constructor_skiplist = obj_constructor_skiplist, interface_skiplist = [:XdpProxyResolverIface], first_list = first_list, doc_prefix = "gdk-pixbuf")

object_method_skiplist=[:get_iter,:advance,:get_file_info_finish,:new_from_stream_async]

GI.export_methods!(ns,path,"gdkpixbuf"; object_method_skiplist = object_method_skiplist, struct_skiplist = struct_skiplist)
GI.export_functions!(ns,path,"gdkpixbuf")
