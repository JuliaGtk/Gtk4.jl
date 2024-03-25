using GObjects
using Test

@testset "gvalue" begin

gv = Ref(GValue())
@test_throws ErrorException gv[Any]
@test_throws ErrorException GObjects.settype!(gv,GBoxed)

types=[Int8,UInt8,Int16,UInt16,Int32,UInt32,Int64,UInt64,Float32,Float64,Bool]

for t=types
    r=rand(t)
    gv=GObjects.gvalue(r)

    @test gv[t]==r
    @test gv[Any]==r
end

r="a string"
gv=GObjects.gvalue(r)
@test gv[String]==r
@test gv[Any]==r

gvboxed=GObjects.gvalue(GKeyFile)
gvboxed[GKeyFile]=GObjects.G_.KeyFile_new()

kf=gvboxed[GKeyFile]
@test isa(kf,GKeyFile)

kf=GObjects.G_.KeyFile_new()
GObjects.G_.set_integer(kf,"group","myint",3)
gvboxed[GKeyFile]=kf
kf2=gvboxed[Any]
@test isa(kf2,GKeyFile)
@test GObjects.G_.get_integer(kf2,"group","myint")==3

kf3=gvboxed[GKeyFile]
@test isa(kf3,GKeyFile)
@test GObjects.G_.get_integer(kf3,"group","myint")==3

gvboxed=GObjects.gvalue(GString)
#gvboxed[GString]=GObjects.string_new("another string")

#s=gvboxed[GString]
#@test isa(s,GString)
#@test bytestring(s.str)=="another string"
@test bytestring("test")=="test"

gvobject=GObjects.gvalue(GObject)
gvobject[GObject]=GObjects.G_.SimpleAction_new("do-something",nothing)

obj=gvobject[GSimpleAction]
@test isa(obj,GSimpleAction)
obj=gvobject[Any]
@test isa(obj,GSimpleAction)

gvs=GObjects.gvalues(3.0,6)
@test Ref(gvs,1)[Any]==3.0
@test Ref(gvs,2)[Any]==6

gvstring = GObjects.gvalue("")
gvnum = GObjects.gvalue(3)

gvstring[] = gvnum
@test gvstring[String] == "3"

end

@testset "gvalue enums" begin

gv = GObjects.gvalue(GObjects.FileType_REGULAR)

gv = GObjects.gvalue(GObjects.BindingFlags_BIDIRECTIONAL)

end

@testset "gobject properties" begin

action_name = "do-something"
a = GSimpleAction(action_name)
@test a.name == action_name
@test get_gtk_property(a, "name") == action_name
@test get_gtk_property(a, "name", String) == action_name
@test get_gtk_property(a, "name", String) == action_name
@test get_gtk_property(a, :name, String) == action_name

@test get_gtk_property(a, :state, GVariant) === nothing

# test AbstractString
astring = SubString("namerino", 1, 4)
@test get_gtk_property(a, astring) == action_name
@test get_gtk_property(a, astring, String) == action_name

a.enabled = true
@test a.enabled

astring = SubString("enablediddley", 1, 7)
set_gtk_property!(a, astring, false)
@test a.enabled == false
set_gtk_property!(a, astring, Bool, 1)

end
