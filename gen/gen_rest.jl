using GI, EzXML
GI.prepend_search_path("/usr/lib64/girepository-1.0")
include("gen_pango.jl")
include("gen_pangocairo.jl")
include("gen_graphene.jl")
include("gen_gsk.jl")
include("gen_gdk4.jl")
include("gen_gtk4.jl")
include("gen_adwaita.jl")
