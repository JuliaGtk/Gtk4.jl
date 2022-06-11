# Text Widgets

There are two basic widgets available for rendering simple text. The one is for
displaying non-editable text `GtkLabel` the other is for editable text `GtkEntry`.

## Label

A `GtkLabel` is the most basic text widget that has already been used behind the
scene in any previous example involving a `GtkButton`.
A `GtkLabel` is constructed by calling
```julia
label = GtkLabel("My text")
```
The text of a label can be changed using the `label` property or `G_.set_text`
```julia
G_.set_text(label,"My other text")
label.label = "My final text"
```
Furthermore, a label has limited support for adding formatted text. This is done
using the `G_.set_markup` function:
```julia
G_.set_markup(label,"""<b>My bold text</b>\n
                          <a href=\"https://www.gtk.org\"
                          title=\"Our website\">GTK+ website</a>""")
```
The syntax for this markup text is borrowed from HTML and explained [here](https://docs.gtk.org/Pango/pango_markup.html).

A label can be made selectable using
```julia
G_.set_selectable(label,true)
```
This can be used if the user should be allowed to copy the text.

The justification of a label can be changed in the following way:
```julia
G_.set_justify(label,Gtk4.Justification_RIGHT)
```
Possible values of the enum `Justification` are `LEFT`,`RIGHT`,`CENTER`, and `FILL`.

Automatic line wrapping can be enabled using
```julia
G_.set_text(label,repeat("Very long text! ",20))
G_.set_wrap(label,true)
```
Note that wrapping will only occur if the size of the widget is limited using layout constraints.

## Entry

The entry widget allows the user to enter text. The entered text can be read and write using
```julia
ent = GtkEntry()
ent.text = "My String"
str = ent.text
```
The maximum number of characters can be limited using `ent.max_length = 10`.

Sometimes you might want to make the widget non-editable. This can be done by the call
```julia
# using the accessor methods
G_.set_editable(GtkEditable(ent),false)
# using the property system
ent.editable = false
```
If you want to use the entry to retrieve passwords you can hide the visibility of the entered text.
This can be achieve by calling
```julia
ent.visibility = false
```
To get notified by changes to the entry one can listen the "changed" event.

## Search Entry

A special variant of the entry that can be used as a search box is `GtkSearchEntry`. It is equipped
with a button to clear the entry.
