using Gtk4, Gtk4.GLib

# Simple demonstration of GtkApplication

function on_state_changed(a,v)
    Gtk4.GLib.set_state(a,v)
    b = v[Bool]
end

function on_new_clicked(a,v)
    notification = GNotification("I wet em'")
    Gtk4.GLib.G_.send_notification(app, "new-window", notification)
    new_window()
end

function new_window()
    window = GtkApplicationWindow(app, "")
    id = Gtk4.id(window)
    window.title = "GtkApplication example: $id"

    button_box = GtkBox(:v)
    push!(window, button_box)

    function on_close_clicked(a,v)
        destroy(window)
    end

    button = GtkButton("Click me to close this window")
    push!(button_box, button)
    button.action_name = "win.close"
    add_action(GActionMap(window),"close",on_close_clicked)

    button = GtkButton("Click me to create a new window")
    push!(button_box, button)
    button.action_name = "app.new_window"

    toggle_button = GtkToggleButton("Toggle me")
    push!(button_box, toggle_button)
    toggle_button.action_name = "app.toggle"

    show(window)
end

function activate(app)
    add_action(GActionMap(app),"new_window",on_new_clicked)
    add_stateful_action(GActionMap(app), "toggle", false, on_state_changed)

    new_window()
end

app = GtkApplication("julia.gtk4.example",
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
