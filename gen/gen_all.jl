using gobject_introspection_jll
ENV["GI_TYPELIB_PATH"]=gobject_introspection_jll.find_artifact_dir()*"/lib/girepository-1.0"
include("gen_glib.jl")
include("gen_gobject.jl")
include("gen_gio.jl")
include("gen_cairo.jl")
#include("gen_pango.jl")
#include("gen_pangocairo.jl")
#include("gen_gdkpixbuf.jl")
#include("gen_graphene.jl")
#include("gen_gsk.jl")
#include("gen_gdk4.jl")
#include("gen_gtk4.jl")
