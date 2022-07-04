module GITestModule
using Test, GI, gobject_introspection_jll
ENV["GI_TYPELIB_PATH"]=gobject_introspection_jll.find_artifact_dir()*"/lib/girepository-1.0"

@testset "GTypeInstance" begin

ns=GI.GINamespace(:Gio,"2.0")
e=ns[:Application]

@test GI.is_gobject(e)

end

@testset "gen" begin

include("../gen/gen_glib.jl")
include("../gen/gen_gobject.jl")
include("../gen/gen_gio.jl")

end

end
