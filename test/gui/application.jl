using Test, Gtk4

@testset "application" begin

app = GtkApplication("julia.gtk4.example",
        Gtk4.GLib.ApplicationFlags_FLAGS_NONE)

Gtk4.GLib.stop_main_loop()  # g_application_run runs the loop and does other important stuff

function activate(app)
  window = GtkApplicationWindow(app, "GtkApplication example")

  function on_clicked(a,v)
    destroy(window)
  end

  function on_state_changed(a,v)
    Gtk4.GLib.set_state(a,v)
    b = v[Bool]
    @async println("state is now $b")
  end

  button_box = GtkBox(:v)
  push!(window, button_box)

  button = GtkButton("Click me to close the window")
  push!(button_box, button)
  button.action_name = "win.close"
  add_action(GActionMap(window),"close",on_clicked)

  toggle_button = GtkToggleButton("Toggle me")
  push!(button_box, toggle_button)
  toggle_button.action_name = "app.toggle"
  add_stateful_action(GActionMap(app), "toggle", false, on_state_changed)

  show(window)

  window2 = GtkWindow("second window")
  push!(app, window2)
  delete!(app, window2)
end

Gtk4.signal_connect(activate, app, :activate)

loop()=Gtk4.run(app)
t = schedule(Task(loop))

end
