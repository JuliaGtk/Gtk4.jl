using Gtk4.Pango
using Test

@testset "families" begin

    fm=Pango.default_font_map()
    l=length(fm)
    i=0
    for fam in fm
        @test isa(fam, PangoFontFamily)
        i=i+1
    end
    @test l == i

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
    end

end
