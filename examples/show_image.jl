using Gtk4, TestImages

win=GtkWindow("Image")
box = GtkBox(:v)

img = testimage("mandrill")
t = Ref(GdkMemoryTexture(img))
pic = GtkPicture(GdkPaintable(t[]))

button = GtkButton("Copy image to clipboard")
signal_connect(button, "clicked") do _
    b = Gtk4.G_.save_to_png_bytes(t[])
    cp = GdkContentProvider("image/png", b)
    c = Gtk4.clipboard(GdkDisplay())
    Gtk4.content(c, cp)
end

button2 = GtkButton("Copy image from clipboard")

function cb(clipboard, resobj)
    try
        t[] = Gtk4.G_.read_texture_finish(clipboard, Gtk4.GLib.GAsyncResult(resobj))
        Gtk4.paintable(pic, GdkPaintable(t[]))
    catch e
        if e isa Gtk4.GLib.GErrorException
            info_dialog(e.message, win) do
            end
        else
            println(e)
        end
    end
    nothing
end

signal_connect(button2, "clicked") do _
    c = Gtk4.clipboard(GdkDisplay())
    cf = Gtk4.formats(c)
    Gtk4.G_.read_texture_async(c, nothing, cb)
end

push!(box, pic)
push!(box, button)
push!(box, button2)

win[] = box
