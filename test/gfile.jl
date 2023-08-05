using Gtk4.GLib
using Test

# for testing handling of GInterfaces

@testset "gfile" begin

path=pwd()

f=GLib.GFile(path)
@test basename(f) == "test"
path2=GLib.path(GFile(f))

@test path==path2

f2=GLib.G_.dup(GFile(f))

@test path==GLib.path(GFile(f2))

@test ispath(GFile(f))

@test isdir(GFile(f))
@test !isfile(GFile(f))

fi = GLib.query_info(f)
@test fi["standard::name"] == "test"
for k in keys(fi)
    q=fi[k]
end
attributes = GLib.G_.list_attributes(fi,nothing)

#fileinfo=Ref{GFileInfo}()

#function query_cb(obj, result)
#    fileinfo[] = GLib.G_.query_info_finish(GFile(GLib.GObjectLeaf(Ptr{GObject}(obj))), GLib.GAsyncResult(GLib.GObjectLeaf(result)))
#end

#GLib.G_.query_info_async(GFile(f),"*",GLib.FileQueryInfoFlags_NONE,GLib.PRIORITY_DEFAULT, nothing, query_cb)

# TODO: add tests for this

end
