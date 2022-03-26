# Layout

You will usually want to add more than one widget to your application. To this end, Gtk4 provides several layout widgets.

!!! note
    For larger projects it is advisable to create the layout using Glade in combination with GtkBuilder [Builder and Glade](@ref).

## Box

The most simple layout widget is the `GtkBox`. It is one-dimensional and can be either be horizontally or vertical aligned.
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
ok.hexpand=true
hbox.spacing = 10
```
The first line sets the `hexpand` property of the `ok` button within the `hbox` container. The second line sets the `spacing` property of `hbox` to 10 pixels.

Note that these aren't evenly sized, and that doesn't change if we set the `cancel` button's `expand` property to `true`. The `homogeneous` property of `hbox` can be used to achieve this.

```julia
hbox.homogeneous = true
```

Now we get this:

![window](figures/twobuttons.png)

which may be closer to what you had in mind.

## Grid

To create two-dimensional (tabular) layouts of widgets, you can use `GtkGrid`:
```julia
win = GtkWindow("A new window")
g = GtkGrid()
a = GtkEntry()  # a widget for entering text
set_gtk_property!(a, :text, "This is Gtk!")
b = GtkCheckButton("Check me!")
c = GtkScale(false, 0:10)     # a slider

# Now let's place these graphical elements into the Grid:
g[1,1] = a    # Cartesian coordinates, g[x,y]
g[2,1] = b
g[1:2,2] = c  # spans both columns
g.column_homogeneous = true
g.column_spacing = 15  # introduce a 15-pixel gap between columns
push!(win, g)
```

The `g[x,y] = obj` assigns the location to the indicated `x,y` positions in the grid
(note that indexing is Cartesian rather than row/column; most graphics packages address the screen using
Cartesian coordinates where 1,1 is in the upper left).
A range is used to indicate a span of grid cells.
By default, each row/column will use only as much space as required to contain the objects,
but you can force them to be of the same size by setting properties like `column_homogeneous`.
