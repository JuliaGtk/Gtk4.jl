using Test, Gtk4

@testset "slider/scale" begin
sl = GtkScale(:v, 1:10)
w = GtkWindow(sl, "Scale")
Gtk4.value(sl, 3)
push!(sl,π,:right,"pi")
push!(sl,-3,:left)
@test Gtk4.value(sl) == 3
adj = GtkAdjustment(sl)
@test get_gtk_property(adj,:value,Float64) == 3
set_gtk_property!(adj,:upper,11)
empty!(sl)

adj2 = GtkAdjustment(5.0,0.0,10.0,1.0,5.0,5.0)

sl2 = GtkScale(:h,adj2)
sl3 = GtkScale(:v)
destroy(w)
end

@testset "spinbutton" begin
sp = GtkSpinButton(1:10)
w = GtkWindow(sp, "SpinButton")
Gtk4.value(sp, 3)
@test Gtk4.value(sp) == 3
destroy(w)

adj = GtkAdjustment(5.0,0.0,10.0,1.0,5.0,5.0)
sp2 = GtkSpinButton(adj, 1.0, 2)
adj2 = GtkAdjustment(sp2)
@test adj == adj2

configure!(adj2; value = 2.0, lower = 1.0, upper = 20.0, step_increment = 2.0, page_increment = 10.0, page_size = 10.0)
@test adj2.value == 2.0
@test adj2.lower == 1.0
@test adj2.upper == 20.0
@test adj2.step_increment == 2.0
@test adj2.page_increment == 10.0
@test adj2.page_size == 10.0
configure!(adj2) # should change nothing
@test adj2.value == 2.0
@test adj2.lower == 1.0
@test adj2.upper == 20.0
@test adj2.step_increment == 2.0
@test adj2.page_increment == 10.0
@test adj2.page_size == 10.0

configure!(sp2; climb_rate = 2.0, digits = 3)
@test sp2.climb_rate == 2.0
@test sp2.digits == 3
configure!(sp2) # should change nothing
@test sp2.climb_rate == 2.0
@test sp2.digits == 3
end

@testset "Entry" begin
e = GtkEntry()
w = GtkWindow(e, "Entry")
set_gtk_property!(e,:text,"initial")
set_gtk_property!(e,:sensitive,false)

b = GtkEntryBuffer("different")
buffer(e, b)
@test e.text == "different"

@test fraction(e) == 0.0
fraction(e, 1.0)
@test fraction(e) == 1.0
pulse_step(e, 1.0)
@test pulse_step(e) == 1.0
pulse(e)

activated = false
signal_connect(e, :activate) do widget
    activated = true
end
signal_emit(e, :activate, Nothing)
@test activated

destroy(w)
end

@testset "DropDown" begin

choices = ["one", "two", "three", "four"]
dd = GtkDropDown(choices)
dd.selected = 1

sl = Gtk4.model(dd)
for (i,s) in enumerate(sl)
    @test s == choices[i]
end
Gtk4.selected_string!(dd, "two")
@test Gtk4.selected_string(dd) == "two"

win = GtkWindow("DropDown Example",400,200)
push!(win, dd)
destroy(win)

dd2 = GtkDropDown()
dd3 = GtkDropDown(1:5)

end

@testset "ScaleButton" begin
sb = GtkScaleButton(0.0:1.0:10.0)
adj = GtkAdjustment(sb)
    
end

@testset "checkbox" begin
w = GtkWindow("Checkbutton")
check = GtkCheckButton("check me"); push!(w,check)
destroy(w)
end

@testset "checkbuttons in group" begin

w = GtkWindow("Checkbutton group test")
b = GtkBox(:v)
cb1 = GtkCheckButton("option 1")
cb2 = GtkCheckButton()
Gtk4.label(cb2, "option 2")
w[]=b
push!(b,cb1)
push!(b,cb2)

group(cb1,cb2)

cb1.active = true
cb2.active = true
@test cb1.active == false

group(cb1,nothing)

cb1.active = true
cb2.active = true
@test cb1.active == true

destroy(w)

end

@testset "togglebuttons in group" begin

w = GtkWindow("Togglebutton group test")
b = GtkBox(:v)
tb1 = GtkToggleButton("option 1")
Gtk4.size_request(tb1,(100,200))
tb2 = GtkToggleButton()
tb2.label = "option 2"
Gtk4.size_request(tb2,100,100)
w[]=b
push!(b,tb1)
push!(b,tb2)

group(tb1,tb2)

tb1.active = true
tb2.active = true
@test tb1.active == false

group(tb1,nothing)

tb1.active = true
tb2.active = true
@test tb1.active == true

destroy(w)

end

@testset "switch and togglebutton" begin
switch = GtkSwitch(true)
w = GtkWindow(switch,"Switch")

function do_something(b, user_data)
    nothing
end

toggle = GtkToggleButton("toggle me")
Gtk4.on_signal_toggled(do_something, toggle)
w[] = toggle

destroy(w)
end

@testset "FontButton" begin
fb = GtkFontButton()
w = GtkWindow(fb)

fb2 = GtkFontButton("Sans Italic 12")

destroy(w)
end

@testset "LinkButton" begin
b = GtkLinkButton("https://github.com/JuliaGtk/Gtk4.jl", "Gtk4.jl", false)
w = GtkWindow(b, "LinkButton")
b2 = GtkLinkButton("https://github.com/JuliaGraphics/Gtk.jl", true)
w[] = b2
destroy(w)
end

@testset "VolumeButton" begin
b = GtkVolumeButton(0.3)
w = GtkWindow(b, "VolumeButton", 50, 50, false)
destroy(w)
end

@testset "ColorButton" begin
b = GtkColorButton()
b = GtkColorButton(GdkRGBA(0, 0.8, 1.0, 0.3))
r = GdkRGBA("red")
@test_throws ErrorException q = GdkRGBA("octarine")
w = GtkWindow(b, "ColorButton", 50, 50)
destroy(w)
end
