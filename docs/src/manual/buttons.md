# Buttons

GTK defines many button and button-like widgets.

## [GtkButton](https://docs.gtk.org/gtk4/class.Button.html)

We have already encountered the widget `GtkButton`, which defines a "clicked" signal that can be used to let the user trigger callback functions.

The button holds a child widget that can be a `GtkLabel` in the case of text, an image-displaying widget in the case of an icon, or potentially anything else you want. The child widget can be set and accessed using `getindex(b::GtkButton)` and `setindex!(b::GtkButton, child_widget::GtkWidget)`:
```julia
b = GtkButton()
b[] = my_widget
child_widget = b[]
```

You can also associate an action (see [Actions](@ref)) with a button by setting its property "action-name".

Selected signals:

| signal | arguments | returns | |
| :--- | :--- | :--- | :--- |
| "clicked" | self::GtkButton | `Nothing` | Emitted when the button is clicked |

## [GtkToggleButton](https://docs.gtk.org/gtk4/class.ToggleButton.html)

This widget looks like a button but it stays pressed when the user clicks it. The state of the button can be accessed or set using its property "active", which is `true` when the button is pressed.

A toggle button can be added to a group using the method `group`, in which case it can be used to select from mutually exclusive options:
```julia
using Gtk4

red_button = GtkToggleButton("red")
green_button = GtkToggleButton("green")
blue_button = GtkToggleButton("blue")
win = GtkWindow("choose one color")
win[] = box = GtkBox(:v)
push!(box, red_button)
push!(box, green_button)
push!(box, blue_button)

group(green_button, red_button)
group(blue_button, red_button)
# now only one button can be active at a time
```

Selected signals:

| signal | arguments |  returns | |
| :--- | :--- | :--- | :--- |
| "toggled" | self::GtkToggleButton | `Nothing` | Emitted when the button state is changed |


## [GtkCheckButton](https://docs.gtk.org/gtk4/class.CheckButton.html)

This widget is a checkbox that can be used to control whether something is active (`true`) or inactive (`false`). Functionally it is identical to a `GtkToggleButton` but it is rendered differently. There is typically a label that is rendered next to the checkbox.

Like a toggle button, a check button can also be added to a group, in which case it is rendered as a "radio button" that can be used to choose from a few mutually exclusive options.

Selected signals:

| signal | arguments | returns | |
| :--- | :--- | :--- | :--- |
| "toggled" | self::GtkCheckButton | `Nothing` | Emitted when the button state is changed |

## [GtkSwitch](https://docs.gtk.org/gtk4/class.Switch.html)

This widget is very much like a check button but looks like a switch.

Like `GtkCheckButton`, its "active" property can be used to get and set the switch's state.

## [GtkLinkButton](https://docs.gtk.org/gtk4/class.LinkButton.html)

This widget can be used to open a URL:

```julia
lb = GtkLinkButton("https://julialang.org","Julia website")
```