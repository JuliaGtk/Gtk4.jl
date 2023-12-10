# Demonstrates keeping the UI responsive while doing tasks in a thread

if Threads.nthreads() == 1 && Threads.nthreads(:interactive) < 1
    @warn("This example is intended to be run with multiple threads enabled.")
end

using Gtk4

btn = GtkButton("Start")
sp = GtkSpinner()
ent = GtkEntry(;hexpand=true)
label = GtkLabel("")

grid = GtkGrid()
lab = GtkLabel("")
grid[1:2,1] = lab
@idle_add lab.label = "The GTK loop is running in thread $(Threads.threadid()) ($(Threads.threadpool()) threadpool)"
grid[1,2] = btn
grid[2,2] = sp
grid[1:2,3] = ent
grid[1:2,4] = label

counter = Ref(0)

signal_connect(btn, "clicked") do widget
    start(sp)
    stop_time = time() + 3
    
    # g_timeout_add can be used to periodically call a function from the main loop
    Gtk4.GLib.g_timeout_add(50) do  # create a function that will be called every 50 milliseconds
        label.label = "counter: $(counter[])"
        return time() < stop_time   # return true to keep calling the function, false to stop
    end
    
    Threads.@spawn begin
        # Do work
        
        counter[] = 0
        while time() < stop_time
            counter[] += 1
        end
        
        tid = Threads.threadid()
        tp = Threads.threadpool()

        # Interacting with GTK from a thread other than the main thread is
        # generally not allowed, so we register an idle callback instead.
        Gtk4.GLib.g_idle_add() do
            stop(sp)
            ent.text = "I counted to $(counter[]) in thread $tid in the $tp threadpool!"
            false
        end
    end
end

win = GtkWindow(grid, "Threads with updating counter", 420, 200)
