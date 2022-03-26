# Combobox

The combobox widget allows for selecting an item from a dropdown menu.
There are two different flavors of comboboxes. A simple `GtkComboBoxText`
widget and a more powerful and generic `GtkComboBox` widget. The former is
a subtype of the later

## GtkComboBoxText

The following example shows how to fill a `GtkComboBoxText` with elements and
listen on the `changed` event

```julia
using Gtk4, Gtk4.G_

cb = GtkComboBoxText()
choices = ["one", "two", "three", "four"]
for choice in choices
  push!(cb,choice)
end
# Lets set the active element to be "two"
cb.active = 1

signal_connect(cb, "changed") do widget, others...
  # get the active index
  idx = cb.active
  # get the active string
  str = G_.get_active_text(cb)
  println("Active element is \"$str\" at index $idx")
end

win = GtkWindow("ComboBoxText Example",400,200)
push!(win, cb)
```

## GtkComboBox

TODO
