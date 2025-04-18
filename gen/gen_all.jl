using GI, EzXML

# Generates code for libraries where we use introspection data outside JLL's
# This code is typically run on a recent version of Fedora where the library
# version is the same or close to what's present in Yggdrasil.

GI.prepend_search_path("/usr/lib64/girepository-1.0")
include("gen_glib.jl")
include("gen_gobject.jl")
include("gen_gio.jl")
include("gen_cairo.jl")
include("gen_gdkpixbuf.jl")
include("gen_pango.jl")
include("gen_pangocairo.jl")
include("gen_graphene.jl")
#include("gen_gsk.jl")
#include("gen_gdk4.jl")
#include("gen_gtk4.jl")
#include("gen_adwaita.jl")
