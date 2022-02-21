using Gtk4.GLib
using Test

# GMenu is a simple object with no properties
# Its constructor is "transfer full" unlike many Gtk constructors

@testset "gmenu" begin

m = GLib.Menu_new()

@test isa(m,GObject)
@test isa(m,GMenuModel)
@test isa(m,GMenu)

GLib.insert(m,0,"test","test-action")

@test 1 == GLib.get_n_items(m)
@test GLib.is_mutable(m)

GLib.freeze(m)

@test false == GLib.is_mutable(m)

i = GLib.MenuItem_new("test2","test2-action")
@test isa(i,GObject)
@test isa(i,GMenuItem)



end
