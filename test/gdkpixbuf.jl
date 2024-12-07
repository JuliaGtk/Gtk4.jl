using Test, Gtk4, Gtk4.GdkPixbufLib, Colors, FixedPointNumbers

@testset "GdkTexture" begin
    img = rand(RGB{N0f8}, 512, 768)
    t = GdkMemoryTexture(img)
    @test size(t) == reverse(size(img)) # image is transposed
    p = GdkPaintable(t)
    pic = GtkPicture(p)

    t2 = GdkMemoryTexture(img,false)
    @test size(t2) == size(img)
    arr = Gtk4.toarray(t2)
    @test size(arr) == size(img)
end

@testset "pixbuf" begin

pb=GdkPixbufLib.G_.Pixbuf_new(0,false,8,300,300)
@test isa(pb,GdkPixbufLib.GdkPixbuf)

@test 300 == width(pb)

x=fill(GdkPixbufLib.RGB(0xff,0xff,0xff),(3,3))
pb[1:3,1:3]=x
@test pb[1,1] == GdkPixbufLib.RGB(0xff,0xff,0xff)
@test pb[1,3] == GdkPixbufLib.RGB(0xff,0xff,0xff)
@test pb[1,4] != GdkPixbufLib.RGB(0xff,0xff,0xff)
@test pb[3,1] == GdkPixbufLib.RGB(0xff,0xff,0xff)
@test pb[4,1] != GdkPixbufLib.RGB(0xff,0xff,0xff)

pb[1,1]=colorant"blue"
@test pb[1,1] == GdkPixbufLib.RGB(0,0,0xff)

cs = GdkPixbufLib.G_.get_colorspace(pb)

end

@testset "Transparent pixbuf" begin
icon = Matrix{GdkPixbufLib.RGBA}(undef, 40, 20)
fill!(icon, GdkPixbufLib.RGBA(0,0xff,0, 0xff))
icon[5:end-5, 3:end-3] .= Ref(GdkPixbufLib.RGBA(0,0,0xff,0x80))
pb=GdkPixbuf(icon, true)
@test eltype(pb) == GdkPixbufLib.RGBA

icon[1,1] = colorant"red"
@test icon[1,1] == GdkPixbufLib.RGBA(0xff,0,0,0xff)
end

