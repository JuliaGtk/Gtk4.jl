# Numeric input widgets

Gtk4 provides a few different widgets for user input of numeric values.

## [GtkScale](https://docs.gtk.org/gtk4/class.Scale.html)

The `GtkScale` widget allows users to select a value by sliding a knob within a predefined range. It is a subclass of [`GtkRange`](https://docs.gtk.org/gtk4/class.Range.html) and displays a slider and, optionally, text showing the current value.

A `GtkScale` is typically created using one of the following constructors:

  * `GtkScale(orientation, range::AbstractRange)` creates a new `GtkScale` with the specified orientation (`:h`/`Orientation_HORIZONTAL` or `:v`/`Orientation_VERTICAL`), with the range of allowed values defined by `range`.
  * `GtkScale(orientation, min_val, max_val, step)` creates a new `GtkScale` with the range of allowed values defined by `min_val`, `max_val`, and `step`.
  * `GtkScale(orientation, adj::GtkAdjustment)` creates a new `GtkScale` using an existing [`GtkAdjustment`](https://docs.gtk.org/gtk4/class.Adjustment.html) object to manage the range and value.

### Example

```julia
using Gtk4

# Create a horizontal scale for integers from 0 to 100
scale = GtkScale(:h, 0.0, 100.0, 1.0)

# Set the initial value
Gtk4.value(scale, 50.0)
```

### Useful properties and signals

| property | type | |
| :--- | :--- | :--- |
| `value` | `Float64` | The current value of the slider. Get/set using `Gtk4.value(widget)` and `Gtk4.value(widget, val)`. |
| `draw_value` | `Bool` | Whether the current value is displayed next to the slider. Defaults to `false`. |
| `digits` | `Int` | The number of decimal places to display for the value. |
| `adjustment` | `GtkAdjustment` | The `GtkAdjustment` managing the scale's range, value, and step. |

The most important signal for interacting with the scale's value is inherited from `GtkRange`:

| signal | arguments | returns | |
| :--- | :--- | :--- | :--- |
| "value-changed" | self::GtkScale | `Nothing` | Emitted when the value is changed |

## [GtkSpinButton](https://docs.gtk.org/gtk4/class.SpinButton.html)

The `GtkSpinButton` widget allows a user to select a value from a numerical range by typing in a text field or by clicking a pair of up/down buttons.
A `GtkSpinButton` is typically created using one of the following constructors:

  * `GtkSpinButton(min_val, max_val, step_increment)` creates a new `GtkSpinButton` with the specified minimum value `min_val`, maximum value `max_val`, and increment size `step_increment`.

  * `GtkSpinButton(adj::GtkAdjustment, climb_rate::Real, digits::Integer)` creates a new `GtkSpinButton` using an existing `GtkAdjustment` object to manage the range and value. The argument `climb_rate` is an internal scaling factor applied to the step increment when the arrow buttons are held down, while `digits` is the number of decimal places to display.

### Example

```julia
using Gtk4

# Create a spin button for integer values from 1 to 10 with step 1
spin = GtkSpinButton(1.0, 10.0, 1.0)

# Set the initial value
Gtk4.value(spin, 5.0)
```

### Useful properties and signals

| property | type | |
| :--- | :--- | :--- |
| `value` | `Float64` | The current numerical value of the widget. Get/set using `Gtk4.value(widget)` and `Gtk4.value(widget, val)`. |
| `adjustment` | `GtkAdjustment` | The object managing the range, value, and step increment. |
| `digits` | `Int` | The number of decimal places to display. |
| `numeric` | `Bool` | Whether only numeric characters are allowed in the entry field. Defaults to `false`. |

The most common signal for tracking changes is:

| signal | arguments | returns | |
| :--- | :--- | :--- | :--- |
| "value-changed" | self::GtkSpinButton | `Nothing` | Emitted when the value is changed. |
