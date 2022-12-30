using Gtk4

c = GtkCanvas()

# define a function that will be called every time the widget needs to be drawn
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

# similarly one can define a function to call when the widget is resized
resize(c) do widget
    # do something that depends on the new widget size
end

# set a cursor to be used when the mouse is over the canvas
cursor(c, "crosshair")

# add the canvas to a window
win = GtkWindow("Canvas")
win[] = c

# add an event controller to handle mouse clicks
g=GtkGestureClick(c)

# add a signal handler for mouse clicks
function on_pressed(controller, n_press, x, y)
    w=widget(controller)
    ctx = getgc(w)
    set_source_rgb(ctx, 0, 1, 0)
    arc(ctx, x, y, 5, 0, 2pi)
    stroke(ctx)
    reveal(w) # triggers a redraw
end
signal_connect(on_pressed, g, "pressed")
