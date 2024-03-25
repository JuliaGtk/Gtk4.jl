using GObjects
using Test

# GDateTime is an opaque struct that is a GBoxed

@testset "datetime" begin

tz=GObjects.G_.TimeZone_new_local()
@test isa(tz,GObjects.GBoxed)

#i=GObjects.find_interval(tz,GObjects.TimeType.STANDARD)
#println("time zone identifier is ",GObjects.get_identifier(tz))
#println("time zone abbreviation is ",GObjects.get_abbreviation(tz,0))

dt=GObjects.G_.DateTime_new_now_local()
@test isa(dt,GObjects.GBoxed)

dt2=GObjects.G_.DateTime_new(tz,2021,10,31,8,41,00)
@test isa(dt2, GObjects.GDateTime)

if dt2 !== nothing
    y,m,d=GObjects.G_.get_ymd(dt2)

    @test y==2021
    @test m==10
    @test d==31
end

end
