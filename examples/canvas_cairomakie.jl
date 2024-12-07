using Gtk4, CairoMakie

config = CairoMakie.ScreenConfig(1.0, 1.0, :good, true, false, nothing)
CairoMakie.activate!()

t_range = 0.0:0.1:10.0
x = rand(length(t_range))
arr() = sin.(t_range) .* Gtk4.value(s) .+ x

canvas = GtkCanvas(400, 200; vexpand=true, hexpand=true)
b = push!(GtkBox(:v),canvas)
w = GtkWindow(b,"CairoMakie example")
s = GtkScale(:h,-5:5; draw_value = true)
push!(b,s)


global f, ax, p = lines(arr())
CairoMakie.autolimits!(ax)

@guarded draw(canvas) do widget
    screen = CairoMakie.Screen(f.scene, config, Gtk4.cairo_surface(canvas))
    CairoMakie.resize!(f.scene, Gtk4.width(widget), Gtk4.height(widget))
    CairoMakie.cairo_draw(screen, f.scene)
end

signal_connect(s, "value-changed") do widget
    global f, ax, p = lines(arr())
    CairoMakie.autolimits!(ax)
    canvas.draw(canvas)
    reveal(canvas)
end
