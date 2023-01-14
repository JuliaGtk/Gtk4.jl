using Gtk4.GLib, Gtk4

@testset "mainloop" begin

GLib.start_main_loop()

x = Ref{Int}(1)

function g_timeout_add_cb()
    x[] = 2
    false
end

g_idle_add(g_timeout_add_cb)
sleep(1.0)
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

# removing a source

x[] = 1 #reset
id = g_timeout_add(1) do
  x[] = 2
  return false # only call once
end
g_source_remove(id)
sleep(0.5)
@test x[] == 1

end

@testset "misc" begin

unhandled = convert(Cint, false)

foo1 = @guarded (x,y) -> x+y
bar1 = @guarded (x,y) -> x+y+k
@guarded foo2(x,y) = x+y
@guarded bar2(x,y) = x+y+k
@guarded function foo3(x,y)
    x+y
end
@guarded function bar3(x,y)
    x+y+k
end
@guarded unhandled function bar4(x,y)
    x+y+k
end

@test foo1(3,5) == 8
@test @test_logs (:warn, "Error in @guarded callback") bar1(3,5) == nothing
@test foo2(3,5) == 8
@test @test_logs (:warn, "Error in @guarded callback") bar2(3,5) == nothing
@test foo3(3,5) == 8
@test @test_logs (:warn, "Error in @guarded callback") bar3(3,5) == nothing
@test @test_logs (:warn, "Error in @guarded callback") bar4(3,5) == unhandled

end
