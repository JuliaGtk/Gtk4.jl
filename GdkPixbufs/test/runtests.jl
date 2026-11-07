module GdkPixbufsTestModule
using Test, GdkPixbufs, Colors

@testset "pixbuf" begin

pb=GdkPixbufs.G_.Pixbuf_new(0,false,8,300,300)
@test isa(pb,GdkPixbufs.GdkPixbuf)

@test 300 == width(pb)

x=fill(GdkPixbufs.RGB(0xff,0xff,0xff),(3,3))
pb[1:3,1:3]=x
@test pb[1,1] == GdkPixbufs.RGB(0xff,0xff,0xff)
@test pb[1,3] == GdkPixbufs.RGB(0xff,0xff,0xff)
@test pb[1,4] != GdkPixbufs.RGB(0xff,0xff,0xff)
@test pb[3,1] == GdkPixbufs.RGB(0xff,0xff,0xff)
@test pb[4,1] != GdkPixbufs.RGB(0xff,0xff,0xff)

pb[1,1]=colorant"blue"
@test pb[1,1] == GdkPixbufs.RGB(0,0,0xff)

cs = GdkPixbufs.G_.get_colorspace(pb)

end

@testset "Transparent pixbuf" begin
icon = Matrix{GdkPixbufs.RGBA}(undef, 40, 20)
fill!(icon, GdkPixbufs.RGBA(0,0xff,0, 0xff))
icon[5:end-5, 3:end-3] .= Ref(GdkPixbufs.RGBA(0,0,0xff,0x80))
pb=GdkPixbuf(icon, true)
@test eltype(pb) == GdkPixbufs.RGBA

icon[1,1] = colorant"red"
@test icon[1,1] == GdkPixbufs.RGBA(0xff,0,0,0xff)
end

end
