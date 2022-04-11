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

repr = Base.print_to_string(a) # should display properties
@test endswith(repr,')')
@test occursin("name=\"do-something\"",repr)
@test occursin("enabled=true",repr)

gpropnames = gtk_propertynames(a)
@test :name in gpropnames
@test :enabled in gpropnames

propnames = propertynames(a)
@test :name in propnames
@test :enabled in propnames
@test :handle in propnames

GLib.propertyinfo(a,:name)

end

@testset "gvariant" begin

types=[Int8,UInt8,Int16,UInt16,Int32,UInt32,Int64,UInt64,Float32,Float64,Bool]

for t=types
    r=rand(t)
    gv=GLib.GVariant(t,r)

    @test gv[t]==r
end

end
