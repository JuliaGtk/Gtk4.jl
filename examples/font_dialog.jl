using Gtk4

function cb(dlg, resobj)
    try
        println(Gtk4.font(dlg, resobj))
    catch e
        println(e)
    end
end

dlg = GtkFontDialog()
Gtk4.choose_font(cb, dlg)

