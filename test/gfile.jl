using Gtk4.GLib
using Test

# for testing handling of GInterfaces

@testset "gfile" begin

path=GLib.get_home_dir()
f=GLib.new_for_path(path)
path2=GLib.get_path(f)

@test path==path2

f2=GLib.dup(f)

@test path==GLib.get_path(f2)

@test GLib.query_exists(f,nothing)

@test GLib.Constants.FileType_DIRECTORY == GLib.query_file_type(f,GLib.Constants.FileQueryInfoFlags.NONE,nothing)

fi = GLib.query_info(f,"*",GLib.Constants.FileQueryInfoFlags.NONE,nothing)
attributes = GLib.list_attributes(fi,nothing)
#println(attributes)

end
