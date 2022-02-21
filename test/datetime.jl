using Gtk4.GLib
using Test

# GDateTime is an opaque struct that is a GBoxed

@testset "datetime" begin

tz=GLib.TimeZone_new_local()
@test isa(tz,GLib.GBoxed)

#i=GLib.find_interval(tz,GLib.Constants.TimeType.STANDARD)
#println("time zone identifier is ",GLib.get_identifier(tz))
#println("time zone abbreviation is ",GLib.get_abbreviation(tz,0))

dt=GLib.DateTime_new_now_local()
@test isa(dt,GLib.GBoxed)

dt2=GLib.DateTime_new(tz,2021,10,31,8,41,00)
y,m,d=GLib.get_ymd(dt2)

@test y==2021
@test m==10
@test d==31

end
