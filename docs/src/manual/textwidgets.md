# Text Widgets

There are two basic widgets available for rendering simple text: `GtkLabel` is for
displaying non-editable text and `GtkEntry` is for editable text.

## GtkLabel

A `GtkLabel` is the most basic text widget and has already been used behind the
scenes in any previous example involving a `GtkButton`.
A `GtkLabel` is constructed by calling
```julia
label = GtkLabel("My text")
```
The text of a label can be changed using the `label` property or `Gtk4.text`
```julia
Gtk4.text(label,"My other text")
label.label = "My final text"
```
Furthermore, a label has limited support for adding formatted text. This is done
using the `Gtk4.markup` function:
```julia
Gtk4.markup(label,"""<b>My bold text</b>\n
                          <a href=\"https://www.gtk.org\"
                          title=\"Our website\">GTK+ website</a>""")
```
The syntax for this markup text is borrowed from HTML and explained [here](https://docs.gtk.org/Pango/pango_markup.html).

A label can be made selectable (so that it can be copied and pasted elsewhere) using
```julia
Gtk4.selectable(label,true)
```

The justification of a label can be changed in the following way:
```julia
Gtk4.justify(label,Gtk4.Justification_RIGHT)
```
Possible values of the enum `Justification` are `LEFT`,`RIGHT`,`CENTER`, and `FILL`.

Automatic line wrapping can be enabled using
```julia
Gtk4.text(label,repeat("Very long text! ",20))
Gtk4.wrap(label,true)
```
Note that wrapping will only occur if the size of the widget is limited by layout constraints.

## GtkEntry

The entry widget allows the user to enter text. The entered text can be read and written using
```julia
ent = GtkEntry()
ent.text = "My String"
str = ent.text
```
A maximum number of characters can be set using `ent.max_length = 10`.

Sometimes you might want to make the widget non-editable. This can be done using the call
```julia
# using the accessor method
Gtk4.editable(GtkEditable(ent),false)
# using the property system
ent.editable = false
```
If you want to use the entry to retrieve passwords you can hide the visibility of the entered text.
This can be achieved by calling
```julia
ent.visibility = false
```
To get notified by changes to the entry one can listen to the "changed" event.

## Search Entry

A special variant of the entry that can be used as a search box is `GtkSearchEntry`. It is equipped
with a button to clear the entry.
