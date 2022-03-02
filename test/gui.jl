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
w = GtkWindow(
    "Frame", 400, 400)
G_.set_child(w,GtkFrame())
#widgets=[f for f in w] # test iteration over GtkBin
#@test length(widgets)==1
destroy(w)
end

@testset "Initially Hidden Canvas" begin
nb = GtkNotebook()
@test hasparent(nb)==false
vbox = G_.Box_new(Gtk4.Constants.Orientation_VERTICAL, 0)
# c = Canvas()
push!(nb, vbox, "A")
#push!(nb, c, "B")
#insert!(nb, 2, GtkLabel("Something in the middle"), "A*")
#pushfirst!(nb, GtkLabel("Something at the beginning"), "First")
# splice!(nb, 3)
w = GtkWindow("TestDataViewer",600,600)
# @test pagenumber(nb,c)==3
G_.set_child(w,nb)
destroy(w)
end

@testset "Labelframe" begin
f = GtkFrame("Label")
w = GtkWindow("Labelframe", 400, 400)
G_.set_child(w, f)
set_gtk_property!(f,:label,"new label")
@test get_gtk_property(f,:label,AbstractString) == "new label"
destroy(w)
end

@testset "notebook" begin
nb = GtkNotebook()
w = GtkWindow("Notebook")
G_.set_child(w,nb)
push!(nb, GtkButton("o_ne"), "tab _one")
push!(nb, GtkButton("t_wo"), "tab _two")
push!(nb, GtkButton("th_ree"), "tab t_hree")
push!(nb, GtkLabel("fo_ur"), "tab _four")
@test length(nb) == 4
set_gtk_property!(nb,:page,2)
@test get_gtk_property(nb,:page,Int) == 2
destroy(w)
end
