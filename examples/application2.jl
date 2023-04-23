using Gtk4, Gtk4.GLib

# Demonstrates GtkApplication + DBus
# Run this in a separate Julia session after starting application.jl
# Probably only useful on Linux

actions = String[]

function update_label(l)
    "toggle" in actions || return
    v=GLib.G_.get_action_state(GActionGroup(remote_action_group),"toggle")
    b=GLib.G_.get_boolean(v)
    Gtk4.G_.set_label(l, b ? "on" : "off")
end

function on_action_added(group, name)
    push!(actions, name)
    if name == "toggle"
        update_label(tlabel)
    end
end

function on_button_clicked(widget)
    "new_window" in actions || return
    GLib.G_.activate_action(GActionGroup(remote_action_group), "new_window", nothing)
end

function activate(app)
    global tlabel = GtkLabel("")
    global remote_action_group = GDBusActionGroup(app, "julia.gtk4.example","/julia/gtk4/example")
    signal_connect(on_action_added, remote_action_group, "action-added")
    actions = GLib.list_actions(remote_action_group)

    # poll for changes in action state
    t = Timer(1, interval=0.05) do timer
        update_label(tlabel)
    end

    window = GtkApplicationWindow(app, "GtkApplication DBus client")
    box = GtkBox(:v)
    window[] = box

    push!(box, tlabel)

    button = GtkButton("Create a new window")
    push!(box, button)

    signal_connect(on_button_clicked, button, "clicked")

    show(window)
end

app = GtkApplication("julia.gtk4.example2",
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
