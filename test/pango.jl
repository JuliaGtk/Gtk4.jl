using Gtk4.Pango, Cairo, Gtk4
using Test

@testset "cairo" begin
    c = CairoRGBSurface(256,256)
    cr = CairoContext(c)
    cr2 = Gtk4.cairoContext(cr)
    layout = PangoLayout(cr2)
end

