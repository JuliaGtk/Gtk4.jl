# Dropdown widgets

One often needs a widget to allow a user to select something from a few options. There are
two easy ways to do this in Gtk4.jl.

## [GtkDropDown](https://docs.gtk.org/gtk4/class.DropDown.html)

A simple option that was introduced in GTK version 4 is `GtkDropDown`. An example is shown below.

```julia
using Gtk4

choices = ["one", "two", "three", "four"]
dd = GtkDropDown(choices)
# Let's set the active element to be "two", keeping in mind that the "selected" property uses 0 based indexing
dd.selected = 1

signal_connect(dd, "notify::selected") do widget, others...
  # get the active index
  idx = dd.selected
  # get the active string
  str = Gtk4.selected_string(dd)
  println("Active element is \"$str\" at index $idx")
end

win = GtkWindow("DropDown Example",400,200)
push!(win, dd)
```

A search entry can be added using `Gtk4.enable_search(dd, true)`. You can set
which item is selected using `selected_string!`.

To change the list of options after the dropdown widget is created, you have to
change its list of strings. The model holding this list can fetched using the
`model` method and then the string list can be modified using the Julia array
interface (`push!`, `pushfirst!`, `empty!`, etc.):
```julia
m = Gtk4.model(dd)
push!(m, "five")
```

More complex uses of `GtkDropDown` are possible by using models other than
`GtkStringList`. This may be supported in future versions of Gtk4.jl.

## [GtkComboBox](https://docs.gtk.org/gtk4/class.ComboBox.html)

The older API for dropdown menu functionality is `GtkComboBox`.
The full, generic `GtkComboBox` widget is powerful but harder to use and won't be covered
here. The simpler `GtkComboBoxText` subtype allows the user to select from text options.

### [GtkComboBoxText](https://docs.gtk.org/gtk4/class.ComboBoxText.html)

The following example shows how to fill a `GtkComboBoxText` with elements and
listen on the `changed` event (this example is functionally equivalent to the example above for `GtkDropDown`):
```julia
using Gtk4

cb = GtkComboBoxText()
choices = ["one", "two", "three", "four"]
for choice in choices
  push!(cb,choice)
end
# Let's set the active element to be "two"
cb.active = 1

signal_connect(cb, "changed") do widget, others...
  # get the active index
  idx = cb.active
  # get the active string
  str = Gtk4.active_text(cb)
  println("Active element is \"$str\" at index $idx")
end

win = GtkWindow("ComboBoxText Example",400,200)
push!(win, cb)
```
