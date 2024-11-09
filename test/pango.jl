using Gtk4.Pango, Cairo, Gtk4
using Test

@testset "layout" begin
    fm=Pango.default_font_map()
    c=PangoContext(fm)
    l=PangoLayout(c)
    text="I am a multiline\nchunk of text."
    Pango.G_.set_text(l,text,-1)
    @test Pango.line_count(l)==2
    @test Pango.text(l) == text

    a=Pango.attributes(l)

    ink,logical=Pango.extents(l)

    width,height=Pango.size(l)

    @test logical.width == width
    @test logical.height == height

    fd=Pango.font_description(l)
end

@testset "font description" begin
    fd2 = PangoFontDescription("Sans")
    show(IOBuffer(), fd2)
    fm=Pango.default_font_map()
    c=PangoContext(fm)
    c[fd2]
end

@testset "families" begin

    fm=Pango.default_font_map()
    l=length(fm)
    i=0
    for fam in fm
        @test isa(fam, PangoFontFamily)
        i=i+1
    end
    @test l == i

    for i in keys(fm)
        @test isa(fm[i], eltype(PangoFontMap))
    end

    if length(fm)>0
        l=length(fm[1])
        i=0
        for face in fm[1]
            @test isa(face,PangoFontFace)
            i=i+1
        end
        @test l == i
        if length(fm[1])>0
            @test isa(fm[1][1],PangoFontFace)
        end

        for i in keys(fm[1])
            @test isa(fm[1][i], eltype(PangoFontFamily))
        end
    end

end

@testset "cairo" begin
    c = CairoRGBSurface(256,256)
    cr = CairoContext(c)
    cr2 = Gtk4.cairoContext(cr)
    layout = PangoLayout(cr2)
end

