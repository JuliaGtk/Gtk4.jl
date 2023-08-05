using Test, Gtk4, Gtk4.GLib, Gtk4.G_, Gtk4.GdkPixbufLib, Cairo

@testset "Button with custom icon (& Pixbuf)" begin
icon = Matrix{GdkPixbufLib.RGB}(undef, 40, 20)
fill!(icon, GdkPixbufLib.RGB(0,0xff,0))
icon[5:end-5, 3:end-3] .= Ref(GdkPixbufLib.RGB(0,0,0xff))
pb=GdkPixbuf(icon, false)
@test eltype(pb) == GdkPixbufLib.RGB
@test size(pb) == (40, 20)
@test pb[1,1].g==0xff
@test pb[1:2,1:2][1,1].g==0xff
@test GdkPixbufLib.bstride(pb,1) == 3
@test GdkPixbufLib.bstride(pb,2) == 3*40
@test GdkPixbufLib.bstride(pb,3) == 0
pb[10,10]=GdkPixbufLib.RGB(0,0,0)
pb[20:30,1:5]=GdkPixbufLib.RGB(0xff,0,0)
im=GtkImage(pb)
bu=GtkButton(im)
w = GtkWindow(bu, "Icon button", 60, 40)
@test bu[]==im
pb2=copy(pb)
if pb2!==nothing
    @test size(pb2,2) == size(pb)[2]
    pb3=slice(pb2,11:20,11:20)
    @test size(pb3) == (10,10)
    fill!(pb3,GdkPixbufLib.RGB(0,0,0))
end
destroy(w)
end

