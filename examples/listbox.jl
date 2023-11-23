using Gtk4

win = GtkWindow("ListBox demo with filter", 300, 800)
box = GtkBox(:v)
entry = GtkSearchEntry()
sw = GtkScrolledWindow()
push!(box, entry)
push!(box, sw)
push!(win, box)

listBox = GtkListBox()
foreach(x-> push!(listBox, GtkLabel(x)), string.(names(Gtk4)))

function match(row)
  label = row.child
  return startswith(label.label, entry.text)
end

Gtk4.set_filter_func(listBox, match)

signal_connect(entry, :search_changed) do w
  @idle_add Gtk4.G_.invalidate_filter(listBox)
end

sw[] = listBox
listBox.vexpand = true

