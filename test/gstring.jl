using Gtk4.GLib
using Test

# GString is a GBoxed struct with fields

@testset "gstring" begin

s=GLib.string_new("string")

@test s.len == 6

GLib.append(s," ")

@test s.len == 7

#GLib.append_c(s,'c')

#@test s.len == 8

GLib.set_size(s,0)

@test s.len == 0

end
