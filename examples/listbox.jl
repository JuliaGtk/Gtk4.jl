using Gtk4

win = GtkWindow("ListBox demo with filter")
box = GtkBox(:v)
entry = GtkSearchEntry()
sw = GtkScrolledWindow()
push!(box, entry)
push!(box, sw)
push!(win, box)

listBox = GtkListBox()
foreach(x-> push!(listBox, GtkLabel(x)), string.(names(Gtk4)))

function match(ptr, _)
  row = convert(GtkListBoxRowLeaf, ptr)
  label = row.child
  result = startswith(label.label, entry.text)
  return result ? Cint(1) : Cint(0)
end

Gtk4.set_filter_func(listBox, (row, data) -> match(row, data))

signal_connect(entry, :search_changed) do w
  @idle_add Gtk4.G_.invalidate_filter(listBox) 
end

sw[] = listBox
listBox.vexpand = true
