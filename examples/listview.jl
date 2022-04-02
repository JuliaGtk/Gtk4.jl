using Gtk4, Gtk4.GLib

win = GtkWindow("Listview demo")
sw = GtkScrolledWindow()
push!(win, sw)

model = GtkStringList(["Apple","Orange","Kiwi"])
factory = GtkSignalListItemFactory()

function setup_cb(f, li)
    set_child(li,GtkLabel(""))
end

function bind_cb(f, li)
    text = li[].string
    label = get_child(li)
    label.label = text
end

list = GtkListView(GtkSelectionModel(GtkSingleSelection(GLib.GListModel(model))), factory)

signal_connect(setup_cb, factory, "setup")
signal_connect(bind_cb, factory, "bind")

sw[] = list
