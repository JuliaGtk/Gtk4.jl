using Gtk4.GLib
using Test

# GBytes is an opaque GBoxed struct

@testset "bytes" begin

f=GLib.MappedFile("test.ini",false)
@test isa(f,GLib.GBoxed)

b=GLib.get_bytes(f)
@test isa(b,GBytes)

a=zeros(UInt8,100)
b2=GLib.Bytes(a)

@test GLib.get_size(b2) == 100

#GLib.ref(b)
#GLib.ref(b2)

#arr = GLib.unref_to_array(b2)

#@test GLib.get_length(arr) == 100
#d=GLib.get_data(arr)
#println(d)

#GLib.ref(arr)

end
