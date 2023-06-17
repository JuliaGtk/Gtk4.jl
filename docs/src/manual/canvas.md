# Drawing with Cairo

!!! note "Example"
    The code on this page can be found in "canvas.jl" in the "example" subdirectory.

Cairo based drawing can be done on Gtk4.jl's `Canvas` widget, which is based on GTK's `GtkDrawingArea`. The canvas widget comes with a backing store Cairo image surface. You control what is drawn on this backing store by defining a `draw` function:

```julia
using Gtk4, Graphics
c = GtkCanvas()
win = GtkWindow(c, "Canvas")
@guarded draw(c) do widget
    ctx = getgc(c)
    h = height(c)
    w = width(c)
    # Paint red rectangle
    rectangle(ctx, 0, 0, w, h/2)
    set_source_rgb(ctx, 1, 0, 0)
    fill(ctx)
    # Paint blue rectangle
    rectangle(ctx, 0, 3h/4, w, h/4)
    set_source_rgb(ctx, 0, 0, 1)
    fill(ctx)
end
```
This `draw` function will be called each time the window is resized or otherwise needs to refresh its display.
If you need to force a redraw of the canvas, you can call `reveal` on the canvas widget.

![canvas](figures/canvas.png)

Errors in the `draw` function can corrupt Gtk4's internal state; if
this happens, you have to quit julia and start a fresh session. To
avoid this problem, the `@guarded` macro wraps your code in a
`try/catch` block and prevents the corruption. It is especially useful
when initially writing and debugging code.

## Mouse events

Mouse events can be handled using event controllers. The event controller for
mouse clicks is `GtkGestureClick`. We first create this event controller, then
add it to the widget using `push!`.

```julia
g=GtkGestureClick()
push!(c,g)

function on_pressed(controller, n_press, x, y)
    w=widget(controller)
    ctx = getgc(w)
    set_source_rgb(ctx, 0, 1, 0)
    arc(ctx, x, y, 5, 0, 2pi)
    stroke(ctx)
    reveal(w)
end

signal_connect(on_pressed, g, "pressed")

```

This will draw a green circle on the canvas at every mouse click.
Resizing the window will make them go away; they were drawn on top of the
canvas one by one, but they weren't added to the `draw` function, which is what
is called when the widget is refreshed.

## Controlling the widget's size

In the example above, the canvas was the direct child of the window, and its size is determined by the window size.
If you instead make the canvas a child of one of GTK's layout widgets, like `GtkBox` or `GtkGrid`, it doesn't appear because by default, the drawing area widget does not expand to fill the space available.
You can override this by setting the canvas's properties `vexpand` and `hexpand` to true.
Alternatively, if you want to set the canvas to have a minimum width and height in pixels, you can set its properties `content_width` and `content_height`.
