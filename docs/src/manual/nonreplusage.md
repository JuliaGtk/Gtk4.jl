# Using Gtk4 outside the REPL

If you're using Gtk4 from command-line scripts, Julia quits before you have a chance to see or interact with your windows. The following design prevents that:

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

By waiting on a `Condition`, Julia will keep running until a signal handler calls `notify(c)`. This pattern allows for multiple events to trigger the condition, such as a button press, or one of many windows to be closed. Program flow will resume at `wait` line, after which it would terminate in this example.

In the common case we simply wish to wait for a single window to be closed, this can be shortened by using `waitforsignal`:

```julia
win = GtkWindow("gtkwait")

# Put your GUI code here

if !isinteractive()
    @async Gtk4.GLib.glib_main()
    Gtk4.GLib.waitforsignal(win,:close_request)
end
```
