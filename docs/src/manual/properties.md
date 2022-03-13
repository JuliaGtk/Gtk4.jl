# Properties

If you're following along, you probably noticed that creating `win` caused quite a lot of output:
```
GtkWindowLeaf(accessible-role=GTK_ACCESSIBLE_ROLE_WINDOW, name="", parent, root, width-request=-1, height-request=-1, visible=TRUE, sensitive=TRUE, can-focus=TRUE, has-focus=FALSE, can-target=TRUE, focus-on-click=TRUE, focusable=FALSE, has-default=FALSE, receives-default=FALSE, cursor, has-tooltip=FALSE, tooltip-markup=NULL, tooltip-text=NULL, opacity=1.000000, overflow=GTK_OVERFLOW_HIDDEN, halign=GTK_ALIGN_FILL, valign=GTK_ALIGN_FILL, margin-start=0, margin-end=0, margin-top=0, margin-bottom=0, hexpand=FALSE, vexpand=FALSE, hexpand-set=FALSE, vexpand-set=FALSE, scale-factor=1, css-name="window", css-classes, layout-manager, title="My window", resizable=TRUE, modal=FALSE, default-width=400, default-height=200, destroy-with-parent=FALSE, hide-on-close=FALSE, icon-name=NULL, display, decorated=TRUE, deletable=TRUE, transient-for, application, default-widget, focus-widget, child, titlebar, handle-menubar-accel=TRUE, is-active=TRUE, startup-id, mnemonics-visible=FALSE, focus-visible=FALSE, maximized=FALSE, fullscreened=FALSE)
```
This shows you a list of properties of the object and their current values. For example, notice that the `title` property is set to `"My window"`. We can change the title in the following way:
```julia
julia> win.title = "New title"
```
or equivalently use `set_gtk_property!`:
```julia
julia> set_gtk_property!(win, :title, "New title")
```

To get the title we can use:
```julia
julia> title = win.title
"New title"
```
or equivalently use `get_gtk_property!`:
```julia
julia> get_gtk_property(win, :title)
"New title"
```
To get the property in a type stable way, you can specify the return type:
```julia
julia> get_gtk_property(win, :title, String)
"New title"
```

To access particular properties using `set_gtk_property!` or `get_gtk_property`, you can either use symbols, like `:title`, or strings, like `"title"`.
When using symbols, you'll need to convert any Gtk property names that use `-` into names with `_`:

```julia
julia> get_gtk_property(win, :default_width)
true
```

Properties that are string-valued or GObject-valued can be set to `nothing`, which is equivalent to setting them to `NULL` in C (or `None` in Python).
A list of valid properties for a GObject instance is returned by `gtk_propertynames`.

Some properties have convenience methods, for example:
```julia
julia> visible(win)
true

julia> visible(win, false)

julia> visible(win)
false

julia> visible(win, true)
```
This sequence makes the window disappear and then reappear.
