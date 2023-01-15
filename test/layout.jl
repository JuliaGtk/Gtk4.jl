using Gtk4.Pango
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
