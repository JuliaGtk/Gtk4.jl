using Gtk4, TestImages

win=GtkWindow("Image")
box = GtkBox(:v)

img = testimage("mandrill")
t = GdkMemoryTexture(img)
p = GdkPaintable(t)

button = GtkButton("Copy image to clipboard")
signal_connect(button, "clicked") do _
    b = Gtk4.G_.save_to_png_bytes(t)
    cp = GdkContentProvider("image/png", b)
    c = Gtk4.clipboard(GdkDisplay())
    Gtk4.content(c, cp)
end

push!(box, GtkPicture(p))
push!(box, button)

win[] = box
