using Gtk4, Adwaita

function activate(app)
    win = AdwApplicationWindow(app)
    box = GtkBox(:v)
    win[] = box
    hb = AdwHeaderBar()
    push!(box, hb)
    title = AdwWindowTitle("Adwaita.jl","example")
    Adwaita.title_widget(hb,title)
    f = AdwFlap()
    push!(box, f)
    Adwaita.flap(f, GtkLabel("Utility Pane"))
    Adwaita.content(f, GtkLabel("Main View"))
    show(win)
end

app = AdwApplication("julia.adwaita.example",
        Gtk4.GLib.ApplicationFlags_FLAGS_NONE)

if isinteractive()
    Gtk4.GLib.stop_main_loop()  # g_application_run will run the loop
end

Gtk4.signal_connect(activate, app, :activate)

# When all windows are closed, loop automatically stops running

if isinteractive()
    loop()=Gtk4.run(app)
    t = schedule(Task(loop))
else
    Gtk4.run(app)
end
