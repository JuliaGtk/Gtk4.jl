using Gtk4.GLib

@testset "mainloop" begin

GLib.start_main_loop()

x = Ref{Int}(1)

function g_timeout_add_cb()
    x[] = 2
    false
end

g_idle_add(g_timeout_add_cb)
sleep(0.5)
@test x[] == 2

x[] = 1 #reset
g_timeout_add(g_timeout_add_cb, 1)
sleep(0.5)
@test x[] == 2

# do syntax

x[] = 1 #reset
g_idle_add() do
  x[] = 2
  return false # only call once
end
sleep(0.5)
@test x[] == 2

x[] = 1 #reset
g_timeout_add(1) do
  x[] = 2
  return false # only call once
end
sleep(0.5)
@test x[] == 2

# macro syntax

x[] = 1 #reset
@idle_add begin
  x[] = 2
end
sleep(0.5)
@test x[] == 2

end
