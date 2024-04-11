using GI

path="../src/gen"

ns = GINamespace(:Gdk,"4.0")
d = readxml("/usr/share/gir-1.0/$(GI.ns_id(ns)).gir")

GI.export_consts!(ns, path, "gdk4"; doc_xml = d)

## structs

toplevel, exprs, exports = GI.output_exprs()

# These are marked as "disguised" and what this means is not documented AFAICT.
disguised = Symbol[]
struct_skiplist=vcat(disguised, [:ToplevelSize,:TextureDownloader])

object_skiplist=Symbol[]

GI.export_struct_exprs!(ns,path, "gdk4", struct_skiplist, [:TimeCoord]; object_constructor_skiplist=[:new_from_resource],doc_xml = d)

push!(struct_skiplist,:ContentFormats)

object_method_skiplist=[:begin,:put_event]
interface_method_skiplist=[:inhibit_system_shortcuts,:show_window_menu]

GI.export_methods!(ns,path,"gdk4"; interface_method_skiplist = interface_method_skiplist, object_method_skiplist = object_method_skiplist, object_skiplist = object_skiplist, struct_skiplist = struct_skiplist)

skiplist=[:events_get_angle,:events_get_center,:events_get_distance]
GI.export_functions!(ns,path,"gdk4"; skiplist = skiplist)
