# List and Tree Widgets

In version 4, GTK introduced new widgets for efficiently displaying
table-like data as one-dimensional lists, trees, or two-dimensional arrays.

## GtkListView

!!! note "Example"
    The code below can be found in "listview.jl" in the ["examples" subdirectory](https://github.com/JuliaGtk/Gtk4.jl/tree/main/examples).

We start with the widget for displaying one-dimensional lists. Here is a simple example:
```julia
using Gtk4

model = GtkStringList(string.(names(Gtk4)))
selmodel = GtkSelectionModel(GtkSingleSelection(GListModel(model)))

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

win = GtkWindow("Listview demo", 250, 800)
sw = GtkScrolledWindow()
win[] = sw
sw[] = list
```
Let's go through each step. First, we create a model that holds the data we want to display. In this
example we display a list of strings (all of the names exported by the `Gtk4` module, which was 1053
strings when this was written), and we store them in a `GtkStringList`. This object implements
the interface `GListModel`, which is what all of the list widgets require.

Next, we create a "selection model", which wraps the model we just created and controls how the user
can select items in the list. Possible wrappers include `GtkNoSelection` (no selection allowed),
`GtkSingleSelection` (a single item can be selected), and `GtkMultiSelection` (multiple items can
be selected).

Next, a "factory" is created. The list widget can efficiently display a huge number of items by only
populating display widgets for an item when the item becomes visible. The "factory" is what does this. The
constructor takes two callback functions: "setup", which creates a suitable widget for displaying an
item, and "bind", which sets the widget to display a particular item. The arguments of the callbacks
are the factory `f` and a list item `li`, which is an object that represents elements of the
GListModel. In the "setup" callback, you can call the function `set_child` on the list item to set a
widget that will be used to display the item. In our example we create a `GtkLabel` to display the
string. In the "bind" callback, we first fetch the element of the list model using the `getindex`
method on the list item (by calling `li[]`) and we get the text from its "string" property. We then
get the `GtkLabel` using the `get_child` function on the list item, and then we set the text of this
`GtkLabel`.

Finally, we construct the `GtkListView` using the selection model and the factory and add it to a
`GtkScrolledWindow` and a `GtkWindow`.

### Filtering

!!! note "Example"
    The code below can be found in "filteredlistview.jl" in the ["examples" subdirectory](https://github.com/JuliaGtk/Gtk4.jl/tree/main/examples).

The list above is very long, and it's useful to allow the user to filter it down. An easy way to
implement this is to use `GtkFilterListModel`, which wraps the model and allows it to be filtered
before being displayed.

Here is an example:
```julia
model = GtkStringList(string.(names(Gtk4)))

entry = GtkSearchEntry()

function match(item)
  return startswith(item.string, entry.text)
end

filter = GtkCustomFilter(match)
filteredModel = GtkFilterListModel(GLib.GListModel(model), filter)
selmodel = GtkSelectionModel(GtkSingleSelection(GListModel(filteredModel)))
```

We create a `GtkCustomFilter` using a `match` callback that returns `true` for items that we want to
display, in our case those that start with the text entered by the user in `entry`. We construct a
`GtkFilterListModel` using this filter and use it instead of the `GListModel` in the constructor
for `GtkSingleSelection`.

Finally, we update the filter when the user changes the text by connecting to the "search-changed" signal:
```julia
signal_connect(entry, :search_changed) do w
  @idle_add Gtk4.changed(filter, Gtk4.FilterChange_DIFFERENT) 
end
```

## Sorting

!!! note "Example"
    The code below can be found in "sortedlistview.jl" in the ["examples" subdirectory](https://github.com/JuliaGtk/Gtk4.jl/tree/main/examples).

It's also useful to be able to sort the list. This can be done using another model wrapper, `GtkSortListModel`.

Here is an example that sorts the list in reverse alphabetical order:
```julia
model = GtkStringList(string.(names(Gtk4)))

ralpha_compare(item1, item2) = isless(item1.string, item2.string) ? 1 : 0

sorter = GtkCustomSorter(match)
sortedModel = GtkSortListModel(GListModel(model), sorter)
```

We create a `GtkCustomSorter` using a `compare` callback that takes two arguments `item1` and `item2` and returns -1 if `item1` is before `item2`, 0 if they are equal, and 1 if `item1` is after `item2`. We construct a `GtkSortListModel` using this filter and use it instead of the `GListModel` in the constructor
for `GtkSingleSelection`.

## GtkColumnView

What if we want to display information in columns? Let's say we want to have one column show the name of the function and another show the number of methods. For this we can use `GtkColumnView`. It works very similarly to `GtkListView`, but instead of having one factory for the entire widget, each column has a factory whose `setup` and `bind` callbacks populate the widgets used to display the information for that column.

Here is an example:
```julia
using Gtk4

win = GtkWindow("ColumnView demo", 450, 800)
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

function bind2_cb(f, li)
    text = li[].string
    label = get_child(li)
    label.label = string(length(methods(eval(Symbol(text)))))
end

list = GtkColumnView(GtkSelectionModel(GtkSingleSelection(GListModel(model))))

factory1 = GtkSignalListItemFactory(setup_cb, bind_cb)
col1 = GtkColumnViewColumn("name", factory1)
push!(list, col1)

factory2 = GtkSignalListItemFactory(setup_cb, bind2_cb)
col2 = GtkColumnViewColumn("methods", factory2)
push!(list, col2)

sw[] = list
```

Note that filtering and sorting work just the same as with `GtkListView` since they operate on the model.

!!! note "Example"
    An example of using `GtkColumnView` with filtering and sorting can be found in "columnview.jl" in the ["examples" subdirectory](https://github.com/JuliaGtk/Gtk4.jl/tree/main/examples).

## GtkTreeView
The `GtkTreeView` was the widget used to display table-like or hierarchical data and trees in version 3 of GTK.
It's also present in version 4 but is being deprecated in the C library in favor of the widgets discussed above.
It will continue to be supported in Gtk4.jl.

### List Store

This widget uses dedicated `GtkListStore` and `GtkTreeStore` containers to hold the data.

Lets start with a very simple example: A table with two columns representing
the name and age of a person. Each column must have a specific type.
We initialize the list store using
```julia
ls = GtkListStore(String, Int)
```
Now we will the store with data
```julia
push!(ls,("Peter",20))
push!(ls,("Paul",30))
push!(ls,("Mary",25))
```
If we want so insert the data at a specific position we can use the insert function
```julia
insert!(ls, 2, ("Susanne", 35))
```
You can use `ls` like a matrix like container. Calling `length` and `size` will give you
```julia
julia> length(ls)
4

julia> size(ls)
(4,2)
```
Specific element can be be accessed using
```julia
julia> ls[1,1]
"Peter"
julia> ls[1,1] = "Pete"
"Pete"
```

### Displaying a list

Now we actually want to display our data. To this end we create a tree view object
```julia
tv = GtkTreeView(GtkTreeModel(ls))
```
Then we need specific renderers for each of the columns. Usually you will only
need a text renderer, but in our example we want to display the boolean value
using a checkbox.
```julia
rTxt = GtkCellRendererText()
rTog = GtkCellRendererToggle()
```
Finally we create for each column a `TreeViewColumn` object
```julia
c1 = GtkTreeViewColumn("Name", rTxt, Dict([("text",0)]))
c2 = GtkTreeViewColumn("Age", rTxt, Dict([("text",1)]))
```
We need to push these column description objects to the tree view
```julia
push!(tv, c1, c2)
```
Then we can display the tree view widget in a window
```julia
win = GtkWindow(tv, "List View")
```
If you prefer that the columns are resizable by the user call
```julia
for c in [c1, c2]
    Gtk4.resizable(c, true)
end
```

### Sorting

We next want to make the tree view sortable
```julia
for (i,c) in enumerate([c1,c2])
  Gtk4.sort_column_id(c,i-1)
end
```
If you now click on one of the column headers, the data will be sorted
with respect to the selected column. You can even make the columns reorderable
```julia
for (i,c) in enumerate([c1, c2])
    Gtk4.reorderable(c, true)
end
```

### Selection

Usually the interesting bit of a list will be the entry being selected. This
is done using an additional `GtkTreeSelection` object that can be retrieved by
```julia
selection = Gtk4.selection(tv)
```
One either have single selection or multiple selections. We toggle this by calling
```julia
Gtk4.mode(selection,Gtk4.SelectionMode_MULTIPLE)
```

For single selection, if we want to know the index of the selected item we can use
```julia
julia> ls[selected(selection),1]
"Pete"
```
For multiple selection, we can get a list of selected rows using `selected_rows`,
which can be used to index the GtkListStore
```julia
julia> [ls[x,1] for x in selected_rows(selection)]
3-element Vector{String}:
 "Susanne"
 "Pete"
 "Paul"
```
Since it can happen that no item has been selected at all, it is a good idea to
put this into an if statement
```julia
if hasselection(selection)
  # do something with selected(selection)
end
```
Sometimes you want to invoke an action of an item is selected. This can be done by
```julia
signal_connect(selection, "changed") do widget
  if hasselection(selection)
    currentIt = selected(selection)

    # now you can to something with the selected item
    println("Name: ", ls[currentIt,1], " Age: ", ls[currentIt,1])
  end
end
```
Another useful signal is "row-activated" that will be triggered by a double click
of the user.

### Filtering

A very useful thing is to apply a filter to a list view such that only a subset
of data is shown. We can do this using the `GtkTreeModelFilter` type. It is
as the `GtkListStore` a `GtkTreeModel` and therefore we can assign it to
a tree view. So the idea is to wrap a `GtkListStore` in a `GtkTreeModelFilter` and
assign that to the tree view.

Next question is how to decide which row of the list store should be shown
and which shouldn't. We will do this by adding an additional column to the list
store that is hidden. The column will be of type `Bool` and a value `true` indicates
that the entry is to be shown while `false` indicates the opposite.
We make the filtering based on this column by a call to `Gtk4.visible_column`.
The full example now looks like this:

```julia
using Gtk4

ls = GtkListStore(String, Int, Bool, Bool)
push!(ls,("Peter",20,false,true))
push!(ls,("Paul",30,false,true))
push!(ls,("Mary",25,true,true))
insert!(ls, 2, ("Susanne",35,true,true))

rTxt = GtkCellRendererText()
rTog = GtkCellRendererToggle()

c1 = GtkTreeViewColumn("Name", rTxt, Dict([("text",0)]), sort_column_id=0)
c2 = GtkTreeViewColumn("Age", rTxt, Dict([("text",1)]), sort_column_id=1)

tmFiltered = GtkTreeModelFilter(ls)
Gtk4.visible_column(tmFiltered,2)
tv = GtkTreeView(GtkTreeModel(tmFiltered))
push!(tv, c1, c2)

selection = Gtk4.selection(tv)

signal_connect(selection, "changed") do widget
  if hasselection(selection)
    currentIt = selected(selection)

    println("Name: ", GtkTreeModel(tmFiltered)[currentIt,1],
            " Age: ", GtkTreeModel(tmFiltered)[currentIt,1])
  end
end

ent = GtkEntry()

signal_connect(ent, "changed") do widget
  searchText = get_gtk_property(ent, :text, String)

  for l=1:length(ls)
    showMe = true

    if length(searchText) > 0
      showMe = showMe && occursin(lowercase(searchText), lowercase(ls[l,1]))
    end

    ls[l,4] = showMe
  end
end

vbox = GtkBox(:v)
push!(vbox,ent,tv)

win = GtkWindow(vbox, "List View with Filter")
```
You can see that we have added a little search bar such that you can see the
filtering in action. It is furthermore important to note that we had to replace
`ls` with `GtkTreeModel(tmFiltered)` in the selection changed callback since
the selection will give an iterator that is only valid in the filtered tree
model.


### Tree Widget

Here is an example of the tree model in action:
```julia
using Gtk4

ts = GtkTreeStore(String)
iter1 = push!(ts,("one",))
iter2 = push!(ts,("two",),iter1)
iter3 = push!(ts,("three",),iter2)
tv = GtkTreeView(GtkTreeModel(ts))
r1 = GtkCellRendererText()
c1 = GtkTreeViewColumn("A", r1, Dict([("text",0)]))
push!(tv,c1)
win = GtkWindow(tv, "Tree View")

iter = Gtk4.iter_from_index(ts, [1])
ts[iter,1] = "ONE"
```
