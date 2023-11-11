using Gtk4

win = GtkWindow("Listview demo with filter")
box = GtkBox(:v)
entry = GtkSearchEntry()
sw = GtkScrolledWindow()
push!(box, entry)
push!(box, sw)
push!(win, box)

modelValues = string.(names(Gtk4))
model = GtkStringList(modelValues)

function setup_cb(f, li)
    set_child(li,GtkLabel(""))
end

function bind_cb(f, li)
    text = li[].string
    label = get_child(li)
    label.label = text
end

factory = GtkSignalListItemFactory(setup_cb, bind_cb)

function match(item)
  return startswith(item.string, entry.text)
end

filt = GtkCustomFilter(match)
filteredModel = GtkFilterListModel(GListModel(model), filt)

list = GtkListView(GtkSelectionModel(GtkSingleSelection(GListModel(filteredModel))), factory)
list.vexpand = true

signal_connect(entry, :search_changed) do w
  @idle_add changed(filt, Gtk4.FilterChange_DIFFERENT)
end

sw[] = list
