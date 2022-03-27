using Test, Gtk4.GdkPixbufLib

@testset "pixbuf" begin

pb=GdkPixbufLib.G_.Pixbuf_new(0,true,8,300,300)
@test isa(pb,GdkPixbufLib.GdkPixbuf)

@test 300 == width(pb)

end

@testset "Transparent pixbuf" begin
icon = Matrix{GdkPixbufLib.RGBA}(undef, 40, 20)
fill!(icon, GdkPixbufLib.RGBA(0,0xff,0, 0xff))
icon[5:end-5, 3:end-3] .= Ref(GdkPixbufLib.RGBA(0,0,0xff,0x80))
pb=GdkPixbuf(data=icon, has_alpha=true)
@test eltype(pb) == GdkPixbufLib.RGBA
end
