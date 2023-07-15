using Gtk4.GLib
using Test

# for testing handling of GInterfaces

@testset "gfile" begin

path=pwd()

f=GLib.GFile(path)
path2=GLib.path(GFile(f))

@test path==path2

f2=GLib.G_.dup(GFile(f))

@test path==GLib.path(GFile(f2))

@test ispath(GFile(f))

@test isdir(GFile(f))

fi = GLib.G_.query_info(GFile(f),"*",GLib.FileQueryInfoFlags_NONE,nothing)
attributes = GLib.G_.list_attributes(fi,nothing)


end
