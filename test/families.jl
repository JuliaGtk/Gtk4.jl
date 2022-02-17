using Gtk4.Pango
using Gtk4.Pango.PangoCairo
using Test

@testset "families" begin

fm=PangoCairo.font_map_get_default()
fams=Pango.list_families(fm)
for fam in fams
    @test isa(fam,PangoFontFamily)
end

if length(fams)>0
    faces=Pango.list_faces(fams[1])
    for face in faces
        @test isa(face,PangoFontFace)
    end
end

end
