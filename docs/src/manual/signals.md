# Signals and Callbacks

A button is not much use if it doesn't do anything.
GTK uses _signals_ as a method for communicating that something of interest has happened.
Most signals will be _emitted_ as a consequence of user interaction: clicking on a button,
closing a window, or just moving the mouse. You _connect_ your signals to particular functions
to make something happen.

Let's try a simple example:
```julia
b = GtkButton("Press me")
win = GtkWindow(b, "Callbacks")

function button_clicked_callback(widget)
    println(widget, " was clicked!")
end

id = signal_connect(button_clicked_callback, b, "clicked")
```

Here, `button_clicked_callback` is a *callback function*, something
designed to be called by GTK to implement the response to user
action.  You use the `signal_connect` function to specify when it
should be called: in this case, when widget `b` (your button) emits
the `"clicked"` signal.

Using Julia's `do` syntax, the exact same code could alternatively be
written as
```julia
b = GtkButton("Press me")
win = GtkWindow(b, "Callbacks")
id = signal_connect(b, "clicked") do widget
     println(widget, " was clicked!")
end
```

If you try this, and click on the button, you should see something like the following:
```
julia> GtkButton(action-name=NULL, action-target, related-action, use-action-appearance=TRUE, name="", parent, width-request=-1, height-request=-1, visible=TRUE, sensitive=TRUE, app-paintable=FALSE, can-focus=TRUE, has-focus=TRUE, is-focus=TRUE, can-default=FALSE, has-default=FALSE, receives-default=TRUE, composite-child=FALSE, style, events=0, no-show-all=FALSE, has-tooltip=FALSE, tooltip-markup=NULL, tooltip-text=NULL, window, double-buffered=TRUE, halign=GTK_ALIGN_FILL, valign=GTK_ALIGN_FILL, margin-left=0, margin-right=0, margin-top=0, margin-bottom=0, margin=0, hexpand=FALSE, vexpand=FALSE, hexpand-set=FALSE, vexpand-set=FALSE, expand=FALSE, border-width=0, resize-mode=GTK_RESIZE_PARENT, child, label="Press me", image, relief=GTK_RELIEF_NORMAL, use-underline=TRUE, use-stock=FALSE, focus-on-click=TRUE, xalign=0.500000, yalign=0.500000, image-position=GTK_POS_LEFT, ) was clicked!
```
That's quite a lot of output; let's just print the label of the button:
```julia
id2 = signal_connect(b, "clicked") do widget
    println("\"", get_gtk_property(widget,:label,String), "\" was clicked!")
end
```
Now you get something like this:
```
julia> GtkButton(action-name=NULL, action-target, related-action, use-action-appearance=TRUE, name="", parent, width-request=-1, height-request=-1, visible=TRUE, sensitive=TRUE, app-paintable=FALSE, can-focus=TRUE, has-focus=TRUE, is-focus=TRUE, can-default=FALSE, has-default=FALSE, receives-default=TRUE, composite-child=FALSE, style, events=0, no-show-all=FALSE, has-tooltip=FALSE, tooltip-markup=NULL, tooltip-text=NULL, window, double-buffered=TRUE, halign=GTK_ALIGN_FILL, valign=GTK_ALIGN_FILL, margin-left=0, margin-right=0, margin-top=0, margin-bottom=0, margin=0, hexpand=FALSE, vexpand=FALSE, hexpand-set=FALSE, vexpand-set=FALSE, expand=FALSE, border-width=0, resize-mode=GTK_RESIZE_PARENT, child, label="Press me", image, relief=GTK_RELIEF_NORMAL, use-underline=TRUE, use-stock=FALSE, focus-on-click=TRUE, xalign=0.500000, yalign=0.500000, image-position=GTK_POS_LEFT, ) was clicked!
"Press me" was clicked!
```
Notice that _both_ of the callback functions executed!
GTK allows you to define multiple signal handlers for a given object; even the execution order can be [specified](https://docs.gtk.org/gobject/concepts.html#signals).
Callbacks for some [signals](https://docs.gtk.org/gtk4/signal.Widget.query-tooltip.html) require that you return an `Int32`, with value 0 if you want the next handler to run or 1 if you want to prevent any other handlers from running on this event.

The [`"clicked"` signal callback](https://docs.gtk.org/gtk4/signal.Button.clicked.html) should return `nothing` (`void` in C parlance), so you can't prevent other callbacks from running.
However, we can disconnect the first signal handler:
```julia
signal_handler_disconnect(b, id)
```
Now clicking on the button just yields
```julia
julia> "Press me" was clicked!
```
Alternatively, you can temporarily enable or disable individual handlers with `signal_handler_block` and `signal_handler_unblock`.

The arguments of the callback depend on the signal type.
Arguments and their meaning are described along with their corresponding signals.
**You should omit the final `user_data` argument described in the GTK documentation**;
keep in mind that you can always address other variables from inside your function block, or define the callback in terms of an anonymous function:
```julia
id = signal_connect((widget, event) -> cb_buttonpressed(widget, event, guistate, drawfunction, ...), b, "button-press-event")
```

## Property notifications

Any time a GObject [property](../manual/properties.md) is changed, a ["notify" signal](https://docs.gtk.org/gobject/signal.Object.notify.html) is emitted.

To set a callback to be called when a window's title is changed, use:
```julia
signal_connect(win, "notify::title") do obj, pspec    # here `obj` is the GObject
    println(obj.title)
end
```

## Alternative approach to signals and signal handlers

!!! warning
    This method and the one described in the next section rely on [closure cfunctions](https://docs.julialang.org/en/v1/manual/calling-c-and-fortran-code/index.html#Closure-cfunctions), which are not supported on all platforms (including ARM). If you're writing code for those platforms, use the method described above. This may be fixed in a future version of Gtk4.

In addition to the "simple" interface described above, Gtk4 includes an approach that allows your callback function to be directly compiled to machine code. Gtk4 makes this easier by using GObject introspection data to look up the return type and parameter types, saving the user the hassle of doing this themselves.

For the "clicked" signal of a `GtkButton`, the equivalent to the example at the beginning of this page is as follows:
```julia
b = GtkButton("Press me")
win = GtkWindow(b, "Callbacks")
function button_cb(::Ptr, b)
    println(b, " was clicked!")
end

on_clicked(cb, b)
```

Note that the main difference here, other than the name of the function being called to connect the signal, is the argument list of the callback. The first argument here is always a pointer to the GObject that sends the signal, which in this case is the `GtkButton`.

The full definition of the function `on_clicked` is
```julia
on_clicked(cb::Function, widget::GtkButton, user_data = widget, after = false)
```
where:
- `cb` is your callback function. This will be compiled with `@cfunction`, and you need to follow its rules. In particular, you should use a generic function
  (i.e., one defined as `function foo(x,y,z) ... end`), and the
  arguments and return type should match the GTK+ documentation for
  the widget and signal ([see
  examples](https://docs.gtk.org/gtk4/signal.Widget.query-tooltip.html)).
  **In contrast with the simpler interface, when writing these callbacks you must include the `user_data` argument**.  See examples below.
- `widget` is the widget that will send the signal
- `user_data` contains any additional information your callback needs
  to operate.  For example, you can pass other widgets, tuples of
  values, etc.  If omitted (as it was in the example above), it defaults to `widget`.
- `after` is a boolean, `true` if you want your callback to run after
  the default handler for your signal. When in doubt, specify `false`.

Functions like this are defined for every signal of every widget supported by Gtk4.jl. They are named `on_signalname`, where signals with `-` in their names have them replaced by underscores `_`. So to connect to `GtkWindow`'s "close-request" signal, you would use `on_close_request`.

When you define the callback, you still have to use the correct argument list or else the call to `@cfunction` will throw an error. It should be `Ptr{GObject}`, `param_types...`, `user_data`. The callback should also return the right type. Functions `signal_return_type(WidgetType, signame)` and `signal_argument_types(WidgetType, signame)` are defined that return the needed types for the signal "signame" of the type "WidgetType".

For example, consider a GUI in which pressing a button updates
a counter:

```julia
box = GtkBox(:h)
button = GtkButton("click me")
label  = GtkLabel("0")
push!(box, button)
push!(box, label)
win = GtkWindow(box, "Callbacks")

const counter = [0]  # Pack counter value inside array to make it a reference

# "clicked" callback declaration is
#     void user_function(GtkButton *button, gpointer user_data)
# But user_data gets converted into a Julia object automatically
function button_cb(widgetptr::Ptr, user_data)
     widget = convert(Gtk4.GtkButtonLeaf, widgetptr)  # pointer -> object
     lbl, cntr = user_data                # unpack the user_data tuple
     cntr[] = cntr[]+1                    # increment counter[1]
     lbl.label = string(cntr[])
     nothing                              # return type is void
end

on_clicked(button_cb, button, (label, counter))
```
Here, the tuple `(label, counter)` was passed in as `user_data`. Note that the value of `counter[]` matches the display in the GUI.

### `@guarded`

The "simple" callback interface includes protections against
corrupting Gtk state from errors, but this `@cfunction`-based approach
does not. Consequently, you may wish to use `@guarded` when writing
these functions. ([Canvas](../manual/canvas.md) draw functions and
mouse event-handling are called through this interface, which is why
you should use `@guarded` there.) For functions that should return a
value, you can specify the value to be returned on error as the first
argument. For example:

```julia
    const unhandled = convert(Int32, false)
    @guarded unhandled function my_callback(widgetptr, ...)
        ...
    end
```

### Old approach to @cfunction based signals
The approach taken by Gtk.jl and earlier versions of Gtk4.jl is still supported, where you supply the return type and parameter types:
```julia
signal_connect(cb, widget, signalname, return_type, parameter_type_tuple, after, user_data=widget)
```
where:

- `cb` is your callback function. This will be compiled with `@cfunction`, and you need to follow its rules. In particular, you should use a generic function
  (i.e., one defined as `function foo(x,y,z) ... end`), and the
  arguments and return type should match the GTK+ documentation for
  the widget and signal ([see
  examples](https://docs.gtk.org/gtk4/signal.Widget.query-tooltip.html)).
  **In contrast with the simpler interface, when writing these callbacks you must include the `user_data` argument**.  See examples below.
- `widget` is the widget that will send the signal
- `signalname` is a string or symbol identifying the signal, e.g.,
  `"clicked"` or `"button-press-event"`
- `return_type` is the type of the value returned by your
  callback. Usually `Nothing` (for `void`) or `Cint` (for `gboolean`)
- `parameter_type_tuple` specifies the types of the *middle* arguments
  to the callback function, omitting the first (the widget) and last
  (`user_data`).  For example, for [`"clicked"`](https://docs.gtk.org/gtk4/signal.Button.clicked.html) we have
  `parameter_type_tuple = ()` (because there are no middle arguments)
  and for [`"button-press-event"`](https://docs.gtk.org/gtk4/signal.GestureClick.pressed.html) we have `parameter_type_tuple =
  (Cint, Cdouble, Cdouble)`.
- `after` is a boolean, `true` if you want your callback to run after
  the default handler for your signal. When in doubt, specify `false`.
- `user_data` contains any additional information your callback needs
  to operate.  For example, you can pass other widgets, tuples of
  values, etc.  If omitted, it defaults to `widget`.

The callback's arguments need to match the GTK documentation, with the
exception of the `user_data` argument. (Rather than being a pointer,
`user_data` will automatically be converted back to an object.)

For example, consider a GUI in which pressing a button updates
a counter:

```julia
box = GtkBox(:h)
button = GtkButton("click me")
label  = GtkLabel("0")
push!(box, button)
push!(box, label)
win = GtkWindow(box, "Callbacks")

const counter = [0]  # Pack counter value inside array to make it a reference

# "clicked" callback declaration is
#     void user_function(GtkButton *button, gpointer user_data)
# But user_data gets converted into a Julia object automatically
function button_cb(widgetptr::Ptr, user_data)
     widget = convert(Gtk4.GtkButtonLeaf, widgetptr)  # pointer -> object
     lbl, cntr = user_data                # unpack the user_data tuple
     cntr[] = cntr[]+1                    # increment counter[1]
     lbl.label = string(cntr[])
     nothing                              # return type is void
end

signal_connect(button_cb, button, "clicked", Nothing, (), false, (label, counter))
```

You should note that the value of `counter[]` matches the display in the GUI.

### Specifying the event type

If your callback function takes an `event` argument, it is important
to declare its type correctly. An easy way to do that is to first
write a callback using the "simple" interface, e.g.,

```julia
    signal_connect(win, "delete-event") do widget, event
        @show typeof(event)
        @show event
    end
```

and then use the reported type in `parameter_type_tuple`.

