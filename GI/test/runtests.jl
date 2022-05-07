module GITestModule
using Test, GI

@testset "GTypeInstance" begin

ns=GI.GINamespace(:Gtk,"4.0")
e=ns[:Window]

@test GI.is_gobject(e)

end

@testset "gen" begin

include("../../gen/gen_glib.jl")
include("../../gen/gen_gobject.jl")
include("../../gen/gen_gio.jl")

end

end
