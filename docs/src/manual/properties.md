# Properties

If you're following along, you probably noticed that creating `win` caused quite a lot of output:
```
Gtk4.GtkWindowLeaf(accessible-role=GTK_ACCESSIBLE_ROLE_WINDOW, name="", parent, root, width-request=-1, height-request=-1, visible=true, sensitive=true, can-focus=true, has-focus=false, can-target=true, focus-on-click=true, focusable=false, has-default=false, receives-default=false, cursor, has-tooltip=false, tooltip-markup=nothing, tooltip-text=nothing, opacity=1.000000, overflow=GTK_OVERFLOW_HIDDEN, halign=GTK_ALIGN_FILL, valign=GTK_ALIGN_FILL, margin-start=0, margin-end=0, margin-top=0, margin-bottom=0, hexpand=false, vexpand=false, hexpand-set=false, vexpand-set=false, scale-factor=1, css-name="window", css-classes, layout-manager, title=nothing, resizable=true, modal=false, default-width=200, default-height=200, destroy-with-parent=false, hide-on-close=false, icon-name=nothing, display, decorated=true, deletable=true, transient-for, application, default-widget, focus-widget, child, titlebar, handle-menubar-accel=true, is-active=false, startup-id, mnemonics-visible=false, focus-visible=false, maximized=false, fullscreened=false)
```
This shows you a list of properties of the object and their current values. All GTK widgets, including windows, are subtypes of GObject, which have various properties that control how the widgets are displayed. For example, notice that the `title` property is set to `"My window"`. In this package, GObject properties are mapped onto Julia properties. We can change the title in the following way:
```julia
julia> win.title = "New title"
```
To get the title we can use:
```julia
julia> title = win.title
"New title"
```

We can also use `set_gtk_property!` and `get_gtk_property!` to set or get GObject properties:
```julia
julia> set_gtk_property!(win, :title, "New title")
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

Properties that are string-valued or GObject-valued can be set to `nothing`,
which is equivalent to setting them to `NULL` in C (or `None` in Python). A list
of all possible property names for a GObject instance is returned by
`gtk_propertynames`.

Properties can be set using keyword arguments in most constructors:
```julia
julia> win = GtkWindow(; title="My title", visible=true)
```

Information about a property, including a description, its GLib type and default
value, can be found using `propertyinfo`:
```julia
julia> propertyinfo(win, :title)
Name: title
GType name: gchararray
Flags: Readable Writable
Description: The title of the window
Default value: nothing
Current value: nothing
```

## Getter and setter methods

Some properties have corresponding getter and setter C methods. It's recommended that you use these when they exist, as they are a little faster and type stable. For example the function `visible` gets or sets the property "visible" of a `GtkWidget`:
```julia
julia> visible(win)
true

julia> visible(win, false)

julia> visible(win)
false

julia> visible(win, true)
```
This sequence makes the window disappear and then reappear.

The most important accessors are exported from `Gtk4` but the more obscure will have to be called including the module name. For example, the property `resizable` for a `GtkWindow`, which controls whether a user is allowed to resize the window, can be set using
```julia
julia> Gtk4.resizable(win, false)
```

## Binding properties

Properties can be bound to one another through the GObject signal system using the method
`bind_property`. For example, if one wanted the title of a window `win2` to automatically track
that of another window `win1`, one could use
```julia
julia> b = bind_property(win1, "title", win2, "title")
```
Now if one calls
```julia
julia> win1.title = "New title"
```
the title of `win2` is automatically updated to the same value. The binding can
be released using `unbind_property(b)`.
