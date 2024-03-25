using GObjects
using Test

# for testing handling of GInterfaces

@testset "gfile" begin

path=pwd()

f=GObjects.GFile(path)
@test basename(f) == "test"
path2=GObjects.path(GFile(f))

@test path==path2

f2=GObjects.G_.dup(GFile(f))

@test path==GObjects.path(GFile(f2))

@test ispath(GFile(f))

@test isdir(GFile(f))
@test !isfile(GFile(f))

fi = GObjects.query_info(f)
@test fi["standard::name"] == "test"
for k in keys(fi)
    q=fi[k]
end
attributes = GObjects.G_.list_attributes(fi,nothing)

#fileinfo=Ref{GFileInfo}()

#function query_cb(obj, result)
#    fileinfo[] = GObjects.G_.query_info_finish(GFile(GObjects.GObjectLeaf(Ptr{GObject}(obj))), GObjects.GAsyncResult(GObjects.GObjectLeaf(result)))
#end

#GObjects.G_.query_info_async(GFile(f),"*",GObjects.FileQueryInfoFlags_NONE,GObjects.PRIORITY_DEFAULT, nothing, query_cb)

# TODO: add tests for this

end
