# Demonstrates keeping the UI responsive while doing tasks in a thread

if Threads.nthreads() == 1 && Threads.nthreads(:interactive) < 1
    @warn("This example is intended to be run with multiple threads enabled.")
end

using Gtk4

btn = GtkButton("Start")
sp = GtkSpinner()
ent = GtkEntry(;hexpand=true)

grid = GtkGrid()
lab = GtkLabel("")
grid[1:2,1] = lab
# @idle_add adds code to be called by the GTK main loop
@idle_add lab.label = "The GTK loop is running in thread $(Threads.threadid()) ($(Threads.threadpool()) threadpool)"
grid[1,2] = btn
grid[2,2] = sp
grid[1:2,3] = ent

signal_connect(btn, "clicked") do widget
    start(sp)   # start the spinner widget
    Threads.@spawn begin
        # Do work in a separate thread to avoid bogging down the GTK main loop
        stop_time = time() + 3
        counter = 0
        while time() < stop_time
            counter += 1
        end
        
        tid = Threads.threadid()
        tp = Threads.threadpool()

        # Interacting with GTK from a thread other than the main thread is
        # generally not allowed, so we register an idle callback instead.
        @idle_add begin
            stop(sp)   # stop the spinner widget
            ent.text = "I counted to $counter in thread $tid in the $tp threadpool!"
            false
        end
    end
end

win = GtkWindow(grid, "Threads", 420, 200)
