using Gtk4.GLib
using Test

# for testing handling of GInterfaces

@testset "gfile" begin

path=pwd()

f=GLib.G_.new_for_path(path)
path2=GLib.G_.get_path(GFile(f))

@test path==path2

f2=GLib.G_.dup(GFile(f))

@test path==GLib.G_.get_path(GFile(f2))

@test GLib.G_.query_exists(GFile(f),nothing)

@test GLib.FileType_DIRECTORY == GLib.G_.query_file_type(GFile(f),GLib.FileQueryInfoFlags_NONE,nothing)

fi = GLib.G_.query_info(GFile(f),"*",GLib.FileQueryInfoFlags_NONE,nothing)
attributes = GLib.G_.list_attributes(fi,nothing)
println(attributes)

fileinfo=Ref{GFileInfo}()

function query_cb(obj, result)
    fileinfo[] = GLib.G_.query_info_finish(GFile(GLib.GObjectLeaf(Ptr{GObject}(obj))), GLib.GAsyncResult(GLib.GObjectLeaf(result)))
end

GLib.G_.query_info_async(GFile(f),"*",GLib.FileQueryInfoFlags_NONE,GLib.PRIORITY_DEFAULT, nothing, query_cb)

# TODO: add tests for this

end
