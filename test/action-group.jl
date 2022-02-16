using Gtk4.GLib
using Test

# GSimpleAction is an object with properties

@testset "gaction" begin

g=GLib.SimpleActionGroup()

@test isa(g,GSimpleActionGroup)
@test [] == GLib.list_actions(GActionGroup(g))

a=GLib.SimpleAction("do-something",nothing)

@test "do-something" == GLib.get_name(GAction(a))
@test a.name == "do-something"

@test nothing == GLib.get_parameter_type(GAction(a))
@test a.parameter_type == nothing
@test a.state == nothing
@test a.state_type == nothing
@test a.enabled == true

end
