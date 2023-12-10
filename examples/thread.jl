# Demonstrates keeping the UI responsive while doing tasks in a thread

if Threads.nthreads() == 1 && Threads.nthreads(:interactive) < 1
    @warn("This example is intended to be run with multiple threads enabled.")
end

using Gtk4

btn = GtkButton("Start")
sp = GtkSpinner()
ent = GtkEntry(;hexpand=true)

ltp = Threads.threadpool()

grid = GtkGrid()
grid[1:2,1] = GtkLabel("The GTK loop is running in thread $(Threads.threadid()) ($ltp threadpool)")
grid[1,2] = btn
grid[2,2] = sp
grid[1:2,3] = ent

signal_connect(btn, "clicked") do widget
    start(sp)
    Threads.@spawn begin
        # Do work
        stop_time = time() + 3
        counter = 0
        while time() < stop_time
            counter += 1
        end
        
        tid = Threads.threadid()
        tp = Threads.threadpool()

        # Interacting with GTK from a thread other than the main thread is
        # generally not allowed, so we register an idle callback instead.
        Gtk4.GLib.g_idle_add() do
            stop(sp)
            ent.text = "I counted to $counter in thread $tid in the $tp threadpool!"
            false
        end
    end
end

win = GtkWindow(grid, "Threads", 420, 200)
