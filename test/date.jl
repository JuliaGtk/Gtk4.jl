using Gtk4.GLib
using Gtk4.GLib.Constants
using Test

# GDate is a GBoxed struct with fields but we force it to be imported as opaque

@testset "date" begin

d=GLib.Date()
@test isa(d,GLib.GBoxed)

d=GLib.Date_new_dmy(5,9,2021)
@test isa(d,GLib.GBoxed)

@test GLib.valid(d)

@test GLib.Constants.DateWeekday_SUNDAY == GLib.get_weekday(d)

@test 248 == GLib.get_day_of_year(d)

dc=GLib.copy(d)

@test 0 == GLib.compare(d,dc)

GLib.add_days(dc,3)

@test GLib.compare(d,dc) < 0

GLib.subtract_days(dc,4)

@test GLib.compare(d,dc) > 0

GLib.order(d,dc)

@test GLib.compare(d,dc) < 0

@test GLib.date_is_leap_year(2020)
@test !GLib.date_is_leap_year(2019)

end
