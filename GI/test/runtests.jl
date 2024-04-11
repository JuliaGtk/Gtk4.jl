using Test, gobject_introspection_jll

if gobject_introspection_jll.is_available()

ENV["GI_TYPELIB_PATH"]=gobject_introspection_jll.find_artifact_dir()*"/lib/girepository-1.0"
using GI, EzXML

@testset "GObject" begin

ns0=GI.GINamespace(:GLib,"2.0")
kf=ns0[:KeyFile]

@test GI.isopaque(kf)
show(ns0[:ucs4_to_utf16])

ns=GI.GINamespace(:Gio,"2.0")
e=ns[:Application]

@test GI.is_gobject(e)

show(e)

a=ns[:Action]
@test length(GI.get_properties(a))==5

show(ns[:AsyncReadyCallback])

deps = GI.get_dependencies(ns)
@test deps == ["GObject-2.0","GLib-2.0"]

deps = GI.get_immediate_dependencies(ns)
@test deps == ["GObject-2.0"]

include("../../gen/gen_all.jl")

end
end
