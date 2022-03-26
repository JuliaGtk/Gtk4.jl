using Gtk4.GLib
using Test

# GSimpleAction is an object with properties

@testset "gaction" begin

g=GLib.G_.SimpleActionGroup_new()

@test isa(g,GSimpleActionGroup)
@test [] == GLib.G_.list_actions(GActionGroup(g))

a=GLib.G_.SimpleAction_new("do-something",nothing)

@test "do-something" == GLib.G_.get_name(GAction(a))
@test a.name == "do-something"

@test nothing == GLib.G_.get_parameter_type(GAction(a))
@test a.parameter_type == nothing
@test a.state == nothing
@test a.state_type == nothing
@test a.enabled == true

end
