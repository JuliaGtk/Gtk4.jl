# Builder

Until now we have created and arranged all widgets entirely using Julia code. While this works fine
for small examples, it has the issue that we are tightly coupling the appearance from our application
with the logic of our program code.

There is an alternative way to design user interfaces that strictly separates the layout
from the code. This is done by an XML based file format that allows for describing any arrangement of widgets.
In order to use the interface in your Julia Gtk4 application you will need `GtkBuilder`.

For GTK version 3 and earlier, [Glade](https://glade.gnome.org) is often used as a GUI tool for creating GtkBuilder XML files in a WYSIWYG (what you see is what you get) manner, but Glade wasn't ported to GTK version 4. Instead [Cambalache](https://flathub.org/apps/details/ar.xjuan.Cambalache) can be used (or the XML can be created by hand).

Once we have created the XML interface the result can be stored in an XML file that usually has
the extension `.ui`. Let's assume we have created a file `myapp.ui` that looks like

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
b = GtkBuilder(filename="path/to/myapp.ui")
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
    For instance, if your UI file is located at `MyPackage/src/builder/myuifile.ui`, you can get the full path using
    `uifile = joinpath(@__DIR__, "builder", "myuifile.ui")`.

In Gtk4.jl a macro `@load_builder` is defined that iterates over the `GtkWidget`s in
a `GtkBuilder` object and automatically assigns them to Julia variables with the same id. For
example, if a `GtkEntry` with an id `entry1` and two `GtkButton`s with id's `button1` and `button2` are present in `myapp.ui`,
calling
```julia
@load_builder(GtkBuilder(filename="myapp.ui"))
```
is equivalent to
```julia
entry1 = b["entry1"]
button1 = b["button1"]
button2 = b["button2"]
```
Note that this only works for `GtkWidget`s that implement the interface `GtkBuildable`, which excludes some objects often defined in UI files, for example `GtkAdjustment`. Those objects will have to be fetched using calls to `get_object`.

## Callbacks

The XML file lets us only describe the visual structure of our widgets and not their behavior when the using
is interacting with it. For this reason, we will have to add callbacks to the widgets which we do in Julia code
as it was described in [Signals and Callbacks](@ref).
