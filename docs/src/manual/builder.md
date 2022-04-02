# Builder and Glade

Until now we have created and arranged all widgets entirely using Julia code. While this works fine
for small examples, it has the issue that we are tightly coupling the appearance from our application
with the logic of our program code. In addition the linear way of procedural Julia code does not fit
very well with complex user interfaces arranged in deeply nested tables and boxes.

Fortunately, there is a much better way to design user interfaces that strictly separate the layout
from the code. This is done by an XML based file format that allows for describing any widget
arrangements. The XML file is usually not manually created but designed graphically using
[Glade](https://glade.gnome.org) in a WYSIWYG (what you see is what you get) manner. In order to use
the interface in your Julia Gtk4 application you will need `GtkBuilder`.

## Glade

Glade lets you create complex user interfaces by graphically arranging them together in a user
friendly way. There are many good [tutorials](https://wiki.gnome.org/action/show/Apps/Glade/Tutorials)
out there so that we will skip a detailed introduction here.

The important thing when putting together the interface with glade is to give each widget that you
later want to interface with a meaningful ID.

!!! note
    Note that Glade can not only be used to create toplevel widgets (e.g. Windows). Instead one can
    start for instance with a `GtkGrid` or `GtkBox` serving as the base for a [Custom/Composed Widgets](@ref).

## Builder

Once we have created the interface with Glade the result can be stored in an XML file that usually has
the extension `.glade`. Lets assume we have created a file `myapp.glade` that looks like

```xml
<?xml version="1.0" encoding="UTF-8"?>
<interface>
  <requires lib="gtk" version="4.0"/>
  <object class="GtkWindow" id="window1">
    <property name="child">
      <object class="GtkButton" id="button1">
        <property name="label" translatable="yes">button</property>
        <property name="use_action_appearance">False</property>
        <property name="focusable">1</property>
        <property name="receives_default">1</property>
        <property name="use_action_appearance">False</property>
      </object>
    </property>
  </object>
</interface>
```

In order to access the widgets from Julia we first create a `GtkBuilder` object that will serve as a
connector between the XML definition and our Julia code.
```julia
b = GtkBuilder(filename="path/to/myapp.glade")
```
Alternatively, if we store the above XML definition in a Julia string `myapp` we can initialize
the builder by
```julia
b = GtkBuilder(buffer=myapp)
```
Now we want to access a widget from the XML file in order to actually display it on the screen. To do so
we can call
```julia
win = b["window1"]
```
for each widget we want to access in our Julia code. Widgets that we don't need
to access from Julia, for example layout widgets like `GtkBox` that are being
used only to arrange more interesting widgets for input or display, do not need
to be loaded. You can thus see your builder as a kind of a widget store that you use
when you need access to your widgets.

!!! note
    If you are developing the code in a package you can get the package directory using the `@__DIR__` macro.
    For instance, if your glade file is located at `MyPackage/src/builder/myuifile.ui`, you can get the full path using
    `uifile = joinpath(@__DIR__, "builder", "myuifile.ui")`.

In Gtk4.jl a macro `@load_builder` is defined that iterates over the `GtkWidget`s in
a `GtkBuilder` object and automatically assigns them to Julia variables with the same id. For
example, if a `GtkEntry` with an id `entry1` and two `GtkButton`s with id's `button1` and `button2` are present in `myapp.glade`,
calling
```julia
@load_builder(GtkBuilder(filename="myapp.glade"))
```
is equivalent to
```julia
entry1 = b["entry1"]
button1 = b["button1"]
button2 = b["button2"]
```
Note that this only works for `GtkWidget`s that implement the interface `GtkBuildable`, which excludes some objects often defined in Glade XML files.

## Callbacks

The XML file lets us only describe the visual structure of our widgets and not their behavior when the using
is interacting with it. For this reason, we will have to add callbacks to the widgets which we do in Julia code
as it was described in [Signals and Callbacks](@ref).
