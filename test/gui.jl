using Gtk4, Gtk4.G_

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
# c = Canvas()
push!(nb, vbox, "A")
#push!(nb, c, "B")
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


@testset "Builder" begin
b=GtkBuilder(;filename="test.glade")
#widgets = [w for w in b]
#@test length(widgets)==length(b)
button = b["a_button"]
@test isa(button,GtkButton)
@test isa(b[1],GtkWidget)

#@test_throws ErrorException b2 = Builder(;filename="test2.glade")
end
