using GI

path="../src/gen"

ns = GINamespace(:Gsk,"4.0")
d = readxml("/usr/share/gir-1.0/$(GI.ns_id(ns)).gir")

GI.export_consts!(ns, path, "gsk4"; doc_xml = d, export_constants = false, exclude_deprecated = false)

# These are marked as "disguised" and what this means is not documentated AFAICT.
disguised = Symbol[]
struct_skiplist=vcat(disguised, [])

object_skiplist=[:FillNode, :StrokeNode, :SubsurfaceNode]

GI.export_struct_exprs!(ns,path, "gsk4", struct_skiplist, [:RoundedRect]; doc_xml = d, output_boxed_cache_init = false, output_boxed_types_def = false, output_object_cache_define = false, output_object_cache_init = false, output_callbacks = false, object_skiplist = object_skiplist, exclude_deprecated = false)

GI.export_methods!(ns,path,"gsk4"; struct_skiplist = struct_skiplist, object_skiplist = object_skiplist, object_method_skiplist = [:deserialize], struct_method_skiplist = [:foreach])
GI.export_functions!(ns,path,"gsk4"; skiplist = [:path_parse])
