using Gtk4

c = GtkCanvas()
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

resize(c) do widget

end
win = GtkWindow("Canvas")
cursor(c, "crosshair")
win[] = c

g=GtkGestureClick(c)

function on_pressed(controller, n_press, x, y)
    w=widget(controller)
    @async println("pressed: $x, $y")
    ev = Gtk4.G_.get_current_event(controller)
    b,x2,y2 = Gtk4.Gdk4.G_.get_position(ev)
    @async println("from event: $x2, $y2")
    ctx = getgc(w)
    set_source_rgb(ctx, 0, 1, 0)
    arc(ctx, x, y, 5, 0, 2pi)
    stroke(ctx)
    reveal(w)
end

signal_connect(on_pressed, g, "pressed")
