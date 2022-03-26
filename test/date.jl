using Gtk4.GLib
using Gtk4.GLib.Constants
using Test

# GDate is a GBoxed struct with fields but we force it to be imported as opaque

@testset "date" begin

d=GLib.G_.Date_new()
@test isa(d,GLib.GBoxed)

d=GLib.G_.Date_new_dmy(5,9,2021)
@test isa(d,GLib.GBoxed)

@test GLib.G_.valid(d)

@test GLib.Constants.DateWeekday_SUNDAY == GLib.G_.get_weekday(d)

@test 248 == GLib.G_.get_day_of_year(d)

dc=GLib.G_.copy(d)

@test 0 == GLib.G_.compare(d,dc)

GLib.G_.add_days(dc,3)

@test GLib.G_.compare(d,dc) < 0

GLib.G_.subtract_days(dc,4)

@test GLib.G_.compare(d,dc) > 0

GLib.G_.order(d,dc)

@test GLib.G_.compare(d,dc) < 0

@test GLib.G_.date_is_leap_year(2020)
@test !GLib.G_.date_is_leap_year(2019)

end
