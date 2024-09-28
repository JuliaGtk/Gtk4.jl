# Menus

A menu lets you organize lots of options or actions. In days of yore there was often an extensive menu bar at the top of an application window. Nowadays it's more common to see a button or two showing more limited menus when clicked.

Menus in GTK are defined using a [menu model](https://docs.gtk.org/gio/class.MenuModel.html). This and related classes are defined in the library libgio rather than libgtk. Thus in Gtk4.jl these objects are defined in the submodule Gtk4.GLib rather than Gtk4.

To define a menu with three simple items, each of which is associated with an action, one could use:
```julia
using Gtk4.GLib

menu = GMenu()
item1 = GMenuItem("Open...", "app.open")
push!(menu,item1)
item2 = GMenuItem("Save...", "app.save")
push!(menu,item2)
item3 = GMenuItem("Quit", "app.quit")
push!(menu,item3)
```

Alternatively one can define menus using GtkBuilder XML rather than Julia code. The above menu would be implemented in XML using:
```julia
using Gtk4, Gtk4.GLib

const menuxml = """
<?xml version="1.0" encoding="UTF-8"?>
<interface>
  <menu id="my_menu">
    <item>
      <attribute name="label">Open...</attribute>
      <attribute name="action">app.open</attribute>
    </item>
    <item>
      <attribute name="label">Save...</attribute>
      <attribute name="action">app.save</attribute>
    </item>
    <item>
      <attribute name="label">Quit</attribute>
      <attribute name="action">app.quit</attribute>
    </item>
  </menu>
</interface>
"""
b = GtkBuilder(menuxml, -1)
menu = b["my_menu"]::Gtk4.GLib.GMenuLeaf
```

[Actions](@ref) that are stateful are automatically shown in menus as toggle items. To organize items it's possible to define sections and submenus.

So far we have just discussed how to define menus. To actually show a menu we have to use one of a few widgets that are discussed below.

## [GtkMenuButton](https://docs.gtk.org/gtk4/class.MenuButton.html)

This button widget presents a menu when clicked. Often the icon used for this button is a "hamburger" (three horizontal lines, GTK icon name "open-menu-symbolic") or three dots (GTK icon name "view-more-symbolic").

The following code creates a menu button with the "hamburger" icon and sets its menu model:
```julia
b = GtkMenuButton(;icon_name="open-menu-symbolic")
menu = create_menu() # method that outputs the menu model (like a GMenu)
Gtk4.menu_model(b, menu)
```

## [GtkPopoverMenu](https://docs.gtk.org/gtk4/class.PopoverMenu.html)

This widget can be used to create a context menu. An example can be found in ImageView.jl.

## Widgets with context menus

Some GTK widgets define their own context menus, for example `GtkLabel`, `GtkEntry`, and `GtkTextView`. To add options to these menus you can use their property `extra-menu`.
