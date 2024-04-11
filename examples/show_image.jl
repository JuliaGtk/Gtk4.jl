using Gtk4, TestImages

win=GtkWindow("Image")
img = testimage("mandrill")
t = GdkMemoryTexture(img')
p = GdkPaintable(t)

win[] = GtkPicture(p)
