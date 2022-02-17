using Gtk4.Pango, Gtk4.Pango.PangoCairo
using Test

@testset "layout" begin

fm=PangoCairo.font_map_get_default()
c=Pango.create_context(fm)
l=Pango.Layout(c)
text="I am a multiline\nchunk of text."
Pango.set_text(l,text,-1)
@test Pango.get_line_count(l)==2
@test Pango.get_text(l) == text

a=Pango.get_attributes(l)

#ink,logical=Pango.get_extents(l)

#width,height=Pango.get_size(l)

#@test logical.width == width
#@test logical.height == height

#fd=Pango.get_font_description(l)


end
