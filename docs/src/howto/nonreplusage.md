# Using Gtk4 outside the REPL

If you're using Gtk4 from command-line scripts, the following design prevents Julia from quitting before you have a chance to see or interact with your windows:

```julia
using Gtk4
win = GtkWindow("gtkwait")

# Put your GUI code here

if !isinteractive()
    c = Condition()
    signal_connect(win, :close_request) do widget
        notify(c)
    end
    @async Gtk4.GLib.glib_main()
    wait(c)
end
```

By waiting on a `Condition`, Julia will keep running until a signal handler calls `notify(c)`. This pattern allows for multiple events to trigger the condition, such as a button press, or one of many windows to be closed. Program flow will resume at the `wait` line, after which it would terminate in this example.

In the common case that we simply wish to wait for a single window to be closed, this can be shortened by using `waitforsignal`:

```julia
using Gtk4
win = GtkWindow("gtkwait")

# Put your GUI code here

if !isinteractive()
    @async Gtk4.GLib.glib_main()
    Gtk4.GLib.waitforsignal(win,:close_request)
end
```

## GtkApplication

For larger projects, you may want to use `GtkApplication`, which enables useful functionality based around `GtkApplicationWindow`, `GAction`, `GActionMap`, etc.
For that you can use the following pattern in a non-interactive script:
```julia
using Gtk4

function activate(app)
    win = GtkApplicationWindow(app, "my title")
    show(win)
end

app = GtkApplication()

Gtk4.signal_connect(activate, app, :activate)

run(app)
```

In the `activate` function, you can create your windows, widgets, etc. and connect them to signals. When all `GtkApplicationWindows` have been closed, the script will exit.

## Creating an app with PackageCompiler

[PackageCompiler.jl](https://github.com/JuliaLang/PackageCompiler.jl) can be used to create an executable file that can be transferred to other computers without installing Julia. An example can be found in the [examples/ExampleApplication](https://github.com/JuliaGtk/Gtk4.jl/tree/main/examples/ExampleApplication) directory in the Gtk4.jl repo.

