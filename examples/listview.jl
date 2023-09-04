using Gtk4, Gtk4.GLib

win = GtkWindow("Listview demo")
sw = GtkScrolledWindow()
push!(win, sw)

model = GtkStringList(string.(names(Gtk4)))

function setup_cb(f, li)
    set_child(li,GtkLabel(""))
end

function bind_cb(f, li)
    text = li[].string
    label = get_child(li)
    label.label = text
end

factory = GtkSignalListItemFactory(setup_cb, bind_cb)
list = GtkListView(GtkSelectionModel(GtkSingleSelection(GLib.GListModel(model))), factory)

sw[] = list
