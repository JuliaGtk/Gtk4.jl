using GObjects
using Test

# GMenu is a simple object with no properties
# Its constructor is "transfer full" unlike many Gtk constructors

@testset "gmenu" begin

m = GObjects.G_.Menu_new()

@test isa(m,GObject)
@test isa(m,GMenuModel)
@test isa(m,GMenu)

GObjects.G_.insert(m,0,"test","test-action")

@test 1 == GObjects.G_.get_n_items(m)
@test GObjects.G_.is_mutable(m)

GObjects.G_.freeze(m)

@test false == GObjects.G_.is_mutable(m)

i = GObjects.G_.MenuItem_new("test2","test2-action")
@test isa(i,GObject)
@test isa(i,GMenuItem)



end
