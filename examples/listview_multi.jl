using Gtk4

win = GtkWindow("Listview demo", 250, 800)
sw = GtkScrolledWindow()
push!(win, sw)

model = GtkStringList(string.(names(Gtk4)))
selmodel = GtkSelectionModel(GtkMultiSelection(GListModel(model)))

function setup_cb(f, li)
    set_child(li,GtkLabel(""))
end

function bind_cb(f, li)
    text = li[].string
    label = get_child(li)
    label.label = text
end

factory = GtkSignalListItemFactory(setup_cb, bind_cb)
list = GtkListView(selmodel, factory)

sel = Gtk4.selection(selmodel)

function ss(w, x, y)
    println("You selected:")
    println(model[sel])
end
signal_connect(ss, selmodel, "selection-changed")

sw[] = list
