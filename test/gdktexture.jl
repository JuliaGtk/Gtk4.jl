using Test, Gtk4, Colors, FixedPointNumbers

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
