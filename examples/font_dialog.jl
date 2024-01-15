using Gtk4

cb(dlg, resobj) = println("you chose "*Gtk4.font(dlg, resobj))

dlg = GtkFontDialog()
Gtk4.choose_font(cb, dlg)

