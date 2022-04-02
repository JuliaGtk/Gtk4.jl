using Gtk4.GLib
using Test

@testset "gvalue" begin

types=[Int8,UInt8,Int16,UInt16,Int32,UInt32,Int64,UInt64,Float32,Float64,Bool]

for t=types
    r=rand(t)
    gv=GLib.gvalue(r)

    @test gv[t]==r
    @test gv[Any]==r
end

r="a string"
gv=GLib.gvalue(r)
@test gv[String]==r
@test gv[Any]==r

gvboxed=GLib.gvalue(GKeyFile)
gvboxed[GKeyFile]=GLib.G_.KeyFile_new()

kf=gvboxed[GKeyFile]
@test isa(kf,GKeyFile)

kf=GLib.G_.KeyFile_new()
GLib.G_.set_integer(kf,"group","myint",3)
gvboxed[GKeyFile]=kf
kf2=gvboxed[Any]
@test isa(kf2,GKeyFile)
@test GLib.G_.get_integer(kf2,"group","myint")==3

kf3=gvboxed[GKeyFile]
@test isa(kf3,GKeyFile)
@test GLib.G_.get_integer(kf3,"group","myint")==3

gvboxed=GLib.gvalue(GString)
#gvboxed[GString]=GLib.string_new("another string")

#s=gvboxed[GString]
#@test isa(s,GString)
#@test bytestring(s.str)=="another string"
@test bytestring("test")=="test"

gvobject=GLib.gvalue(GObject)
gvobject[GObject]=GLib.G_.SimpleAction_new("do-something",nothing)

obj=gvobject[GSimpleAction]
@test isa(obj,GSimpleAction)
obj=gvobject[Any]
@test isa(obj,GSimpleAction)

gvs=GLib.gvalues(3.0,6)
@test Ref(gvs,1)[Any]==3.0
@test Ref(gvs,2)[Any]==6

gvstring = GLib.gvalue("")
gvnum = GLib.gvalue(3)

gvstring[] = gvnum
@test gvstring[String] == "3"

end
