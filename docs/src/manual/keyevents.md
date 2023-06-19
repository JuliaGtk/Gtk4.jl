# Key Events

## Key press events

To capture a keyboard event, one can add a GtkEventControllerKey to a widget (for example, a window) and add a callback, as shown in the following example.

```julia
using Gtk4

win = GtkWindow("Key Press Example")
eck = GtkEventControllerKey(win)

signal_connect(eck, "key-pressed") do controller, keyval, keycode, state
    println("You pressed key ", keyval, " which is '", Char(keyval), "'.")
end
```

You can then check if `event.keyval` has a certain value
and invoke an action in that case.

## Modifiers

To detect combination keypresses like "Control-w", you can use the argument `state`, which is a `GdkModifierType`.
```julia
using Gtk4

win = GtkWindow("Control-W to close")
eck = GtkEventControllerKey(win)

signal_connect(eck, "key-pressed") do controller, keyval, keycode, state
    mask = Gtk4.ModifierType_CONTROL_MASK
    if ((ModifierType(state & Gtk4.MODIFIER_MASK) & mask == mask) && keyval == UInt('w'))
        close(widget(eck))
    end
end
```

## Key release events

The following example captures the events for both a key press and a key release
and reports the time duration between the two.
There is some state handling here because of the likely event that your keyboard is set to "repeat" a pressed key after some initial delay and because it is possible to press multiple keys at once.
This version reports the time elapsed between the _initial_ key press and the key release.

```julia
using Gtk4

const start_times = Dict{UInt32, UInt32}()

w = GtkWindow("Key Press/Release Example")
eck = GtkEventControllerKey(w)

id1 = signal_connect(eck, "key-pressed") do controller, keyval, keycode, state
    if keyval ∉ keys(start_times)
        start_times[keyval] = Gtk4.current_event_time(controller) # save the initial key press time
        println("You pressed key ", keyval, " which is '", Char(keyval), "'.")
    else
        println("repeating key ", keyval)
    end
end

id2 = signal_connect(eck, "key-released") do controller, keyval, keycode, state
    start_time = pop!(start_times, keyval) # remove the key from the dictionary
    event = Gtk4.current_event(controller)
    duration = Gtk4.time(event) - start_time # key press duration in milliseconds
    println("You released key ", keyval, " after time ", duration, " msec.")
end
```
