using Gtk4.GLib
using Test

@testset "GObject" begin

@test signal_return_type(GObject, :notify) == Nothing
@test signal_argument_types(GObject, :notify) == (Ptr{GParamSpec},)

end

# GMenu is a simple object with no properties
# Its constructor is "transfer full" unlike many Gtk constructors

@testset "gmenu" begin

m = GLib.G_.Menu_new()

@test isa(m,GObject)
@test isa(m,GMenuModel)
@test isa(m,GMenu)

GLib.G_.insert(m,0,"test","test-action")

@test 1 == GLib.G_.get_n_items(m)
@test GLib.G_.is_mutable(m)

GLib.G_.freeze(m)

@test false == GLib.G_.is_mutable(m)

i = GLib.G_.MenuItem_new("test2","test2-action")
@test isa(i,GObject)
@test isa(i,GMenuItem)



end
