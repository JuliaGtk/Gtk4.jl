using Gtk4

# Column view with filtering and sorting

win = GtkWindow("ColumnView demo", 450, 800)
bx = GtkBox(:v)
sw = GtkScrolledWindow()
push!(win, bx)
hbx = GtkBox(:h)
entry = GtkSearchEntry()
sort_control = GtkDropDown(["Alphabetical","Reverse alphabetical","# methods (most to least)"])
push!(hbx, entry, sort_control)
push!(bx, hbx, sw)

# The model

model = GtkStringList(string.(names(Gtk4)))

# Sorting

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

sorter = GtkCustomSorter(alpha_compare)
sortedModel = GtkSortListModel(GListModel(model), sorter)

function match(item)
  return startswith(item.string, entry.text)
end

# Filtering

filt = GtkCustomFilter(match)
filteredModel = GtkFilterListModel(GListModel(sortedModel), filt)

signal_connect(entry, :search_changed) do w
  @idle_add changed(filt, Gtk4.FilterChange_DIFFERENT)
end

# Create ColumnView

function setup_cb(f, li)
    set_child(li,GtkLabel(""))
end

function bind_cb(f, li)
    text = li[].string
    label = get_child(li)
    label.label = text
end

function bind2_cb(f, li)
    text = li[].string
    label = get_child(li)
    label.label = string(length(methods(eval(Symbol(text)))))
end

list = GtkColumnView(GtkSelectionModel(GtkSingleSelection(GListModel(filteredModel))); vexpand=true)
factory1 = GtkSignalListItemFactory(setup_cb, bind_cb)
col1 = GtkColumnViewColumn("name", factory1; expand=true)
push!(list, col1)

factory2 = GtkSignalListItemFactory(setup_cb, bind2_cb)
col2 = GtkColumnViewColumn("methods", factory2)
push!(list, col2)

sw[] = list

