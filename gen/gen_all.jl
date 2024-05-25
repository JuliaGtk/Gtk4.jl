using gobject_introspection_jll, gdk_pixbuf_jll
using GI

# Generates code for libraries where introspection data is present in JLL's
# This should work on any Linux machine

GI.prepend_search_path(gobject_introspection_jll)
GI.prepend_search_path(gdk_pixbuf_jll)
include("gen_glib.jl")
include("gen_gobject.jl")
include("gen_gio.jl")
include("gen_cairo.jl")
include("gen_gdkpixbuf.jl")

