using Gtk4, Gtk4.GLib

win = GtkWindow("Listview demo with filter")
box = GtkBox(:v)
entry = GtkSearchEntry()
sw = GtkScrolledWindow()
push!(box, entry)
push!(box, sw)
push!(win, box)

modelValues = string.(names(Gtk4))
model = GtkStringList(modelValues)
factory = GtkSignalListItemFactory()

function setup_cb(f, li)
    set_child(li,GtkLabel(""))
end

function bind_cb(f, li)
    text = li[].string
    label = get_child(li)
    label.label = text
end

function match(list_item, user_data)
  itemLeaf = Gtk4.GLib.find_leaf_type(list_item)
  item = convert(itemLeaf, list_item)
  result = startswith(item.string, entry.text)
  return result ? Cint(1) : Cint(0)
end

filter = GtkCustomFilter((li, ud) -> match(li, ud))
filteredModel = GtkFilterListModel(GLib.GListModel(model), filter)

list = GtkListView(GtkSelectionModel(GtkSingleSelection(GLib.GListModel(filteredModel))), factory)
list.vexpand = true

signal_connect(setup_cb, factory, "setup")
signal_connect(bind_cb, factory, "bind")

signal_connect(entry, :search_changed) do w
  @idle_add Gtk4.G_.changed(filter, Gtk4.FilterChange_DIFFERENT) 
end

sw[] = list
