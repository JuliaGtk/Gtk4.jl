using Gtk4, Gtk4.G_, Gtk4.GLib

# For testing callbacks
activate(w::GtkWidget) = G_.activate(w)

@testset "Window" begin
w = GtkWindow("Window", 400, 300)

# if !Sys.iswindows()
#     # On windows, the wrong screen sizes are reported
#     @test width(w) == 400
#     @test height(w) == 300
#     @test size(w) == (400, 300)
#     wdth, hght = screen_size(w)
#     @test wdth > 0 && hght > 0
# end
# G_.gravity(w,10) #GRAVITY_STATIC
# sleep(0.1)

## Check Window positions
# pos = G_.position(w)
# if G_.position(w) != pos
#     @warn("The Window Manager did move the Gtk Window in show")
# end
# G_.position(w, 100, 100)
# sleep(0.1)
# if G_.position(w) == pos
#     @warn("The Window Manager did not move the Gtk Window when requested")
# end
@test get_gtk_property(w, "title", AbstractString) == "Window"
set_gtk_property!(w, :title, "Window 2")
@test get_gtk_property(w, :title, AbstractString) == "Window 2"
visible(w,false)
@test visible(w) == false
visible(w,true)
@test visible(w) == true

# gw = Gtk.gdk_window(w)
# ox, oy = Gtk.get_origin(gw)
#
hide(w)
show(w)
grab_focus(w)
#
# destroy(w); yield()
# @test !get_gtk_property(w, :visible, Bool)
# w=WeakRef(w)
# GC.gc(); yield(); GC.gc()
# #@test w.value === nothing    ### fails inside @testset
end

@testset "get/set property" begin
    w = GtkWindow("Window", 400, 300)
    @test w.title == "Window"
    @test w.visible
    w.visible = false
    @test w.visible == false
    destroy(w)
end

@testset "change Window size" begin
    w = GtkWindow("Window", 400, 300)
    fullscreen(w)
    sleep(1)
    unfullscreen(w)
    sleep(1)
    maximize(w)
    sleep(1)
    if !G_.is_maximized(w)
        @warn("The Window Manager did not maximize the Gtk Window when requested")
    end
    unmaximize(w)
    sleep(1)
    @test !G_.is_maximized(w)
    destroy(w)
end

@testset "Frame" begin
w = GtkWindow(GtkFrame(),
    "Frame", 400, 400)
#widgets=[f for f in w] # test iteration over GtkBin
#@test length(widgets)==1
destroy(w)
end

@testset "Initially Hidden Canvas" begin
nb = GtkNotebook()
@test hasparent(nb)==false
vbox = GtkBox(:v)
c = GtkCanvas()
push!(nb, vbox, "A")
push!(nb, c, "B")
#insert!(nb, 2, GtkLabel("Something in the middle"), "A*")
#pushfirst!(nb, GtkLabel("Something at the beginning"), "First")
# splice!(nb, 3)
w = GtkWindow(nb,"TestDataViewer",600,600)
# @test pagenumber(nb,c)==3
destroy(w)
end

@testset "Labelframe" begin
f = GtkFrame("Label")
w = GtkWindow(f,"Labelframe", 400, 400)
set_gtk_property!(f,:label,"new label")
@test get_gtk_property(f,:label,AbstractString) == "new label"
destroy(w)
end

@testset "notebook" begin
nb = GtkNotebook()
w = GtkWindow(nb,"Notebook")
push!(nb, GtkButton("o_ne"), "tab _one")
push!(nb, GtkButton("t_wo"), "tab _two")
push!(nb, GtkButton("th_ree"), "tab t_hree")
push!(nb, GtkLabel("fo_ur"), "tab _four")
@test length(nb) == 4
set_gtk_property!(nb,:page,2)
@test get_gtk_property(nb,:page,Int) == 2
destroy(w)
end

@testset "Panedwindow" begin
pw = GtkPaned(:h)
w = GtkWindow(pw,"Panedwindow", 400, 400)
pw2 = GtkPaned(:v)
pw[1]=GtkButton("one")
pw[2]=pw2
@test pw[2]==pw2
pw2[1]=GtkButton("two")
pw2[2]=GtkButton("three")
destroy(w)
end

@testset "Iteration and toplevel" begin
## example of last in first covered
## Create this GUI, then shrink window with the mouse
f = GtkBox(:v)
w = GtkWindow(f,"Last in, first covered", 400, 400)

g1 = GtkBox(:h)
g2 = GtkBox(:h)
push!(f,g1)
push!(f,g2)
#@test f[1]==g1

b11 = GtkButton("first")
push!(g1, b11)
b12 = GtkButton("second")
push!(g1, b12)
b21 = GtkButton("first")
push!(g2, b21)
b22 = GtkButton("second")
push!(g2, b22)

strs = ["first", "second"]
i = 1
for child in g1
    @test get_gtk_property(child,:label,AbstractString) == strs[i]
    @test toplevel(child) == w
    i += 1
end
# set_gtk_property!(g1,:pack_type,b11,0) #GTK_PACK_START
# set_gtk_property!(g1,:pack_type,b12,0) #GTK_PACK_START
# set_gtk_property!(g2,:pack_type,b21,1) #GTK_PACK_END
# set_gtk_property!(g2,:pack_type,b22,1) #GTK_PACK_END
# @test get_gtk_property(g1,:pack_type, b11, Int) == 0

## Now shrink window
destroy(w)
end

@testset "Grid" begin
    grid = GtkGrid()
    w = GtkWindow(grid,"Grid", 400, 400)
    b=GtkButton("2,2")
    grid[2,2] = b
    @test grid[2,2] == b
    grid[2,3] = GtkButton("2,3")
    grid[1,1] = GtkLabel("grid")
    grid[3,1:3] = GtkButton("Tall button")
    insert!(grid,1,:top)
    insert!(grid,3,:bottom)
    #insert!(grid,grid[1,2],:right)
    #deleteat!(grid,1,:row)
    #empty!(grid)
    destroy(w)
end

## Widgets

@testset "button, label" begin
w = GtkWindow("Widgets")
f = GtkBox(:v)
G_.set_child(w,f)
l = GtkLabel("label"); push!(f,l)
b = GtkButton("button"); push!(f,b)

set_gtk_property!(l,:label,"new label")
@test get_gtk_property(l,:label,AbstractString) == "new label"
set_gtk_property!(b,:label,"new label")
@test get_gtk_property(b,:label,AbstractString) == "new label"

counter = 0
id = signal_connect(b, "activate") do widget
    counter::Int += 1
end
@test GLib.signal_handler_is_connected(b, id)

@test counter == 0
activate(b)
@test counter == 1
signal_handler_block(b, id)
activate(b)
@test counter == 1
signal_handler_unblock(b, id)
activate(b)
@test counter == 2
signal_handler_disconnect(b, id)
activate(b)
@test counter == 2
destroy(w)
end


@testset "slider/scale" begin
sl = GtkScale(true, 1:10)
w = GtkWindow(sl, "Scale")
G_.set_value(sl, 3)
@test G_.get_value(sl) == 3
adj = GtkAdjustment(sl)
@test get_gtk_property(adj,:value,Float64) == 3
set_gtk_property!(adj,:upper,11)
destroy(w)
end

@testset "spinbutton" begin
sp = GtkSpinButton(1:10)
w = GtkWindow(sp, "SpinButton")
G_.set_value(sp, 3)
@test G_.get_value(sp) == 3
destroy(w)
end

@testset "progressbar" begin
pb = GtkProgressBar()
w = GtkWindow(pb, "Progress bar")
set_gtk_property!(pb,:fraction,0.7)
@test get_gtk_property(pb,:fraction,Float64) == 0.7
pulse(pb)
destroy(w)
end

@testset "spinner" begin
s = GtkSpinner()
w = GtkWindow(s, "Spinner")
start(s)
@test get_gtk_property(s,:spinning,Bool) == true
stop(s)
@test get_gtk_property(s,:spinning,Bool) == false

destroy(w)
end

@testset "Entry" begin
e = GtkEntry()
w = GtkWindow(e, "Entry")
set_gtk_property!(e,:text,"initial")
set_gtk_property!(e,:sensitive,false)

activated = false
signal_connect(e, :activate) do widget
    activated = true
end
signal_emit(e, :activate, Nothing)
@test activated

destroy(w)
end

@testset "Statusbar" begin
vbox = GtkBox(:v)
w = GtkWindow(vbox, "Statusbar")
global sb = GtkStatusbar()  # closures are not yet c-callable
push!(vbox, sb)
ctxid = Gtk4.context_id(sb, "Statusbar example")
bpush = GtkButton("push item")
bpop = GtkButton("pop item")
push!(vbox, bpush)
push!(vbox, bpop)
global sb_count = 1
function cb_sbpush(ptr,evt,id)
    push!(sb, id, string("Item ", sb_count))
    sb_count += 1
    convert(Int32,false)
end
function cb_sbpop(ptr,evt,id)
    pop!(sb, id)
    convert(Int32,false)
end
#on_signal_button_press(cb_sbpush, bpush, false, ctxid)
#on_signal_button_press(cb_sbpop, bpop, false, ctxid)

#click(bpush)
#click(bpop)
empty!(sb,ctxid)
destroy(w)
end


@testset "Builder" begin
b=GtkBuilder(;filename="test.glade")
#widgets = [w for w in b]
#@test length(widgets)==length(b)
button = b["a_button"]
@test isa(button,GtkButton)
@test isa(b[1],GtkWidget)

#@test_throws ErrorException b2 = Builder(;filename="test2.glade")

s = open("test.glade","r") do f
    read(f,String)
end
b3 = GtkBuilder(;buffer = s)


end

@testset "Canvas & AspectFrame" begin
c = GtkCanvas()
f = GtkAspectFrame(0.5, 1, 0.5)
G_.set_child(f,c)
w = GtkWindow(f, "Canvas")
c.draw = function(_)
    if isdefined(c,:back)
        ctx = Gtk4.getgc(c)
        set_source_rgb(ctx, 1.0, 0.0, 0.0)
        paint(ctx)
    end
end
draw(c)
destroy(w)
end

# @testset "SetCoordinates" begin
#     cnvs = GtkCanvas()
#     win = GtkWindow(cnvs)
#     draw(cnvs) do c
#         println("hello?")
#         set_coordinates(getgc(c), BoundingBox(0, 1, 0, 1))
#     end
#     sleep(0.5)
#     mtrx = Gtk.Cairo.get_matrix(getgc(cnvs))
#     @test mtrx.xx == 300
#     @test mtrx.yy == 280
#     @test mtrx.xy == mtrx.yx == mtrx.x0 == mtrx.y0 == 0
#     surf = Gtk.cairo_surface(cnvs)
#     #a = Gtk.allocation(cnvs)
#     #@test isa(a,Gtk.GdkRectangle)
# end
