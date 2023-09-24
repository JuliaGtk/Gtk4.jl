# Layout

Gtk4 provides many layout widgets for arranging widgets in a window.

!!! note
    For larger projects it might be a good idea to create the layout using Cambalache in combination with `GtkBuilder`. See [Builder](@ref).

## GtkBox

The layout widget used most often is `GtkBox`. It is one-dimensional and can be either be horizontally or vertical aligned.
```julia
win = GtkWindow("New title")
hbox = GtkBox(:h)  # :h makes a horizontal layout, :v a vertical layout
push!(win, hbox)
cancel = GtkButton("Cancel")
ok = GtkButton("OK")
push!(hbox, cancel)
push!(hbox, ok)
```

This layout may not be exactly what you'd like. Perhaps you'd like the `OK` button to fill the available space, and to insert some blank space between them:

```julia
ok.hexpand = true
hbox.spacing = 10
```
The first line sets the `hexpand` property of the `ok` button within the `hbox` container. In GTK4, a separate `vexpand` property controls whether the widget expands in the vertical direction. The second line sets the `spacing` property of `hbox` to 10 pixels.

Note that these aren't evenly sized, and that doesn't change if we set the `cancel` button's `hexpand` property to `true`. The `homogeneous` property of `hbox` can be used to achieve this.

```julia
hbox.homogeneous = true
```

To add a line between widgets in a `GtkBox`, you can use `GtkSeparator`.

```julia
sep = GtkSeparator(:h)
push!(hbox, sep)
# add more widgets here
```

Julia interface methods defined for `GtkBox`:

| method | what it does |
| :--- | :--- |
| `push!(b::GtkBox, w::GtkWidget)` | Adds a widget to the end of the box |
| `pushfirst!(b::GtkBox, w::GtkWidget)` | Adds a widget to the beginning of the box |
| `delete!(b::GtkBox, w::GtkWidget)` | Removes a widget from the box |
| `empty!(b::GtkBox)` | Removes all widgets from the box |

## GtkGrid

To create two-dimensional (tabular) layouts of widgets, you can use `GtkGrid`:
```julia
win = GtkWindow("A new window")
g = GtkGrid()
a = GtkEntry()  # a widget for entering text
a.text = "This is Gtk!"
b = GtkCheckButton("Check me!")
c = GtkScale(:h, 0:10)     # a slider

# Now let's place these graphical elements into the Grid:
g[1,1] = a    # Cartesian coordinates, g[x,y]
g[2,1] = b
g[1:2,2] = c  # spans both columns
g.column_homogeneous = true # grid forces columns to have the same width
g.column_spacing = 15  # introduce a 15-pixel gap between columns
push!(win, g)
```

The `g[x,y] = obj` assigns the location to the indicated `x,y` positions in the grid
(note that indexing is Cartesian rather than row/column; most graphics packages address the screen using
Cartesian coordinates where 1,1 is in the upper left).
A range is used to indicate a span of grid cells.
By default, each row/column will use only as much space as required to contain the objects,
but you can force them to be of the same size by setting properties like `column_homogeneous`.

A useful method for `GtkGrid` is `query_child`, which can be used to get the coordinates and span of a widget currently in the grid:
```julia
julia> Gtk4.query_child(g,c)
(1, 2, 2, 1)
```
Here, 1 is the column, 2 is the row, and the widget spans 2 columns and 1 row.

Julia interface methods defined for `GtkGrid`:

| method | what it does |
| :--- | :--- |
| `getindex(g::GtkGrid, c::Integer, r::Integer)` or `g[c,r]` | Gets a widget, where `c` and `r` are the column and row indices |
| `setindex!(g::GtkGrid, w::GtkWidget, c::Integer, r::Integer)` or `g[i,j] = w` | Sets a widget |
| `insert!(g::GtkGrid, i::Integer, side)` | Inserts a row or column next to the existing row or column with index `i`; `side` can be `:left`, `:right`, `top`, or `bottom`. |
| `insert!(g::GtkGrid, sibling::GtkWidget, side)` | Inserts a row or column next to the existing widget `sibling` that is already in the grid; `side` can be `:left`, `:right`, `top`, or `bottom`. |
| `delete!(g::GtkGrid, w::GtkWidget)` | Removes a widget from the grid |
| `empty!(g::GtkGrid)` | Removes all widgets from the grid |

## GtkCenterBox

The `GtkCenterBox` widget can hold 3 widgets in a line, either horizontally or
vertically oriented. It keeps the middle widget centered. Child widgets can be set and accessed like this:
```julia
cb = GtkCenterBox(:h)   # :h makes a horizontal layout, :v a vertical layout
cb[:start] = GtkButton("Left")
cb[:center] = GtkButton("Center")
cb[:end] = GtkButton("Right")
```
For vertical orientation, `:start` refers to the top widget and `:end` to the
bottom widget.

Julia interface methods defined for `GtkCenterBox`:

| method | what it does |
| :--- | :--- |
| `getindex(b::GtkCenterBox, pos::Symbol)` or `b[pos]` | Gets a widget, where `pos` is `:start`, `:center`, or `:end` |
| `setindex!(b::GtkCenterBox, w::GtkWidget, pos::Symbol)` or `b[pos] = w` | Sets a widget |

## GtkPaned

The `GtkPaned` widget creates two slots separated by a movable divider. Like `GtkBox` and `GtkCenterBox`, it can
be oriented either vertically or horizontally. To add child widgets, you can use
```julia
paned = GtkPaned()
paned[1] = top_or_left_widget
paned[2] = bottom_or_right_widget
```

Julia interface methods defined for `GtkPaned`:

| method | what it does |
| :--- | :--- |
| `getindex(b::GtkPaned, i::Integer)` or `b[i]` | Gets a widget, where `i` is 1 or 2 |
| `setindex!(b::GtkPaned, w::GtkWidget, i::Integer)` or `b[i] = w` | Sets a widget |

## GtkNotebook

The `GtkNotebook` widget places child widgets in tabs like a browser window.
Child widgets can be inserted with a label like this:
```julia
nb = GtkNotebook()
vbox = GtkBox(:v)
hbox = GtkBox(:h)
push!(nb, vbox, "Vertical")  # here "Vertical" is the label for the tab
push!(nb, hbox, "Horizontal")
```

Julia interface methods defined for `GtkNotebook`:

| method | what it does |
| :--- | :--- |
| `push!(n::GtkNotebook, x::GtkWidget, label::AbstractString)` | Appends a widget with a label |
| `push!(n::GtkNotebook, x::GtkWidget, label::GtkWidget)` | Appends a widget with a widget to be shown in the tab |
| `pushfirst!(n::GtkNotebook, x::GtkWidget, label::AbstractString)` | Prepends a widget with a label |
| `pushfirst!(n::GtkNotebook, x::GtkWidget, label::GtkWidget)` | Prepends a widget with a widget to be shown in the tab |
| `deleteat!(n::GtkNotebook, x::GtkWidget)` | Removes a widget from the notebook |
| `empty!(n::GtkNotebook)` | Removes all widgets from the notebook |

## GtkStack

The `GtkStack` widget is a lot like `GtkNotebook`, but a separate widget `GtkStackSwitcher` controls what page is shown.
An interface very similar to `GtkNotebook` is defined:
```julia
s = GtkStack()
sw = GtkStackSwitcher()
vbox = GtkBox(:v)
push!(vbox, sw)
push!(vbox, s)
push!(s, GtkLabel("First label"), "id1", "Label 1")  # first string is an id, second is a label
push!(s, GtkLabel("Second label"), "id2", "Label 2") # widget can be retrieved using s[id]
```

Julia interface methods defined for `GtkStack`:

| method | what it does |
| :--- | :--- |
| `getindex(s::GtkStack, name::AbstractString)` or `s[name]` | Gets a widget by name |
| `setindex!(s::GtkStack, x::GtkWidget, name::AbstractString)` or `s[name] = x` | Sets a widget by name |
| `push!(s::GtkStack, x::GtkWidget)` | Appends a widget |
| `push!(s::GtkStack, x::GtkWidget, name::AbstractString)` | Appends a widget with a name |
| `push!(s::GtkStack, x::GtkWidget, name::AbstractString, title::AbstractString)` | Appends a widget with a name and a title |
| `delete!(s::GtkStack, x::GtkWidget)` | Removes a widget from the stack |
| `empty!(s::GtkStack)` | Removes all widgets from the stack |

## GtkFrame, GtkAspectFrame, and GtkExpander

These widgets hold one child widget. `GtkFrame` and `GtkAspectFrame` display them in a decorative frame with an optional label. `GtkExpander` allows the user to hide the child.

Julia interface methods defined for `GtkFrame`, `GtkAspectFrame`, and `GtkExpander`:

| method | what it does |
| :--- | :--- |
| `getindex(f)` or `f[]` | Gets the child widget |
| `setindex!(f, w::Union{GtkWidget,Nothing})` or `f[] = w` | Sets or clears the child widget |

## Iterating over child widgets

For any of the widgets described above (or any `GtkWidget` that has children), you can iterate over all child widgets using
```julia
for child in widget
    myfunc(child)
end
```
