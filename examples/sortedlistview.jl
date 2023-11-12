using Gtk4

win = GtkWindow("Listview demo with sort", 300, 800)
box = GtkBox(:v)
sort_control = GtkDropDown(["Alphabetical","Reverse alphabetical","# methods (most to least)"])
sw = GtkScrolledWindow()
push!(box, sort_control)
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

# define sorting functions (should return -1 if item1 is before item2, 0 if they are equal, and 1 if item1 is after item2
alpha_compare(item1, item2) = isless(item1.string, item2.string) ? -1 : 1   # alphabetical
ralpha_compare(item1, item2) = -alpha_compare(item1, item2)                 # reverse alphabetical
function methods_compare(item1, item2)
    n1 = length(methods(eval(Symbol(item1.string))))
    n2 = length(methods(eval(Symbol(item2.string))))
    if n1 == n2
        return 0
    end
    isless(n1,n2) ? 1 : -1
end

sorter = GtkCustomSorter(alpha_compare)
sortedModel = GtkSortListModel(GListModel(model), sorter)

list = GtkListView(GtkSelectionModel(GtkSingleSelection(GListModel(sortedModel))), factory)
list.vexpand = true

signal_connect(sort_control, "notify::selected") do w, others...
  sel = Gtk4.selected_string(w)
  c = if sel == "Alphabetical"
      alpha_compare
  elseif sel == "Reverse alphabetical"
      ralpha_compare
  elseif sel == "# methods (most to least)"
      methods_compare
  end
  @idle_add begin
      Gtk4.set_sort_func(sorter, c)
      changed(sorter)
  end
end

sw[] = list
