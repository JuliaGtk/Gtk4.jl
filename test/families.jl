using Gtk4.Pango
using Test

@testset "families" begin

fm=Pango.default_font_map()
fams=Pango.G_.list_families(fm)
for fam in fams
    @test isa(fam,PangoFontFamily)
end

if length(fams)>0
    faces=Pango.G_.list_faces(fams[1])
    for face in faces
        @test isa(face,PangoFontFace)
    end
end

end
