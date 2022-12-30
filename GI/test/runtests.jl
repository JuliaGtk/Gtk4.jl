using Test, gobject_introspection_jll

if gobject_introspection_jll.is_available()

ENV["GI_TYPELIB_PATH"]=gobject_introspection_jll.find_artifact_dir()*"/lib/girepository-1.0"
using GI, EzXML

@testset "GObject" begin

ns=GI.GINamespace(:Gio,"2.0")
e=ns[:Application]

@test GI.is_gobject(e)

include("../../gen/gen_all.jl")

end
end
