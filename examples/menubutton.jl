using Gtk4, Gtk4.GLib

# simple example defining a menu and showing it using a GtkMenuButton

# the menu items are grayed out and unresponsive because no actions are defined!

win = GtkWindow("MenuButton example")
mb = GtkMenuButton(;icon_name="open-menu-symbolic")

menu = GMenu()
item1 = GMenuItem("Open...", "app.open")
push!(menu,item1)
item2 = GMenuItem("Save...", "app.save")
push!(menu,item2)
item3 = GMenuItem("Quit", "app.quit")
push!(menu,item3)

Gtk4.menu_model(mb, menu)

win[] = mb

