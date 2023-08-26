using Test, Gtk4, Gtk4.G_

@testset "get/set property and binding" begin
    w = GtkWindow("Window", 400, 300)
    @test w.title == "Window"
    @test w.visible
    w.visible = false
    @test w.visible == false

    # test Enum property set/get
    @test w.halign == Gtk4.Align_FILL  # default value
    w.halign = Gtk4.Align_CENTER
    @test w.halign == Gtk4.Align_CENTER

    w2 = GtkWindow("Window 2")
    b=bind_property(w,:title,w2,:title,GLib.BindingFlags_SYNC_CREATE)
    @test w2.title == w.title

    @test b.source == w
    @test b.source_property == "title"
    @test b.target == w2
    @test b.target_property == "title"

    # test Flags property get
    @test b.flags == GLib.BindingFlags_SYNC_CREATE

    w.title = "Another title"
    @test w2.title == w.title

    unbind_property(b)

    w.title = "New title"

    @test w2.title != w.title

    w.title = nothing
    @test w.title === nothing

    @test w.cursor === nothing
    cursor(w,"crosshair")
    @test w.cursor != nothing
    cursor(w,nothing)
    @test w.cursor === nothing

    c = GdkCursor("crosshair")
    w.cursor = c
    @test w.cursor == c
    w.cursor = nothing
    @test w.cursor === nothing

    destroy(w)
    destroy(w2)
end

@testset "Iteration and toplevel" begin
## example of last in first covered
## Create this GUI, then shrink window with the mouse
f = GtkBox(:v)
w = GtkWindow(f,"Last in, first covered", 400, 400)

g1 = GtkBox(:h)
g2 = GtkBox(:h)
@test_throws ErrorException g3 = GtkBox(:w)
push!(f,g1)
push!(f,g2)

b11 = GtkButton("first")
push!(g1, b11)
b12 = GtkButton(:mnemonic,"_second")
push!(g1, b12)
b21 = GtkButton(:label,"first")
b22 = GtkButton(:icon_name,"document-open-symbolic")
@test_throws ErrorException GtkButton(:shiny,"shiny")
push!(g2, b22)
pushfirst!(g2, b21)
push!(g2, GtkSeparator(:h))
@test_throws ErrorException push!(g2, b11)
function n_children(w::GtkWidget)
    i=0
    for c in w
        i=i+1
    end
    i
end

@test n_children(g2) == 3
empty!(g2)
@test n_children(g2) == 0

strs = ["first", "_second"]
i = 1
for child in g1
    @test get_gtk_property(child,:label,AbstractString) == strs[i]
    @test toplevel(child) == w
    i += 1
end

destroy(w)
end

@testset "button, label" begin
w = GtkWindow("Widgets")
f = GtkBox(:v)
Gtk4.child(w,f)
l = GtkLabel("label"); push!(f,l)
b = GtkButton("button"); push!(f,b)

counter = 0
id = signal_connect(b, "activate") do widget
    counter::Int += 1
end
function incr(widget, user_data)  # incrementing counter in this crashes julia
    nothing
end
Gtk4.on_signal_clicked(incr, b)
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

@testset "Builder" begin
b=GtkBuilder("test.ui")
widgets = [w for w in b]
@test length(widgets)==length(b)
@test length(b)==6
button = b["a_button"]
@test isa(button,GtkButton)
@test isa(b[1],GtkWidget)

@load_builder(b)

destroy(a_window)

@test button == b["a_button"]

s = open("test.ui","r") do f
    read(f,String)
end
b3 = GtkBuilder(s,-1)
win = b3["a_window"]
destroy(win)

b4 = GtkBuilder()
push!(b4; filename="test.ui")

b5 = GtkBuilder()
Sys.WORD_SIZE == 64 && push!(b5; buffer=s)

end

@testset "CssProviderLeaf(filename=\"...\")" begin
    style_file = joinpath(dirname(@__FILE__), "style_test.css")

    l = GtkLabel("I am some large blue text!")

    provider = GtkCssProvider(nothing,style_file)

    sc = Gtk4.style_context(l)
    push!(sc, provider, 600)

    w = GtkWindow(l)
    show(w)

    ### add css tests here

    destroy(w)
end

@testset "keyval" begin
@test keyval("H") == Gtk4.KEY_H
end

@testset "IconTheme" begin
    i = GtkIconTheme(GdkDisplay())
    Gtk4.icon_theme_add_search_path(i, ".")
end

@testset "Menus" begin
using Gtk4.GLib

menubar = GMenu()
filemenu = GMenu()
open_ = GMenuItem("Open","open")
push!(filemenu, open_)
new_ = GMenuItem("New")
newsubmenu = GMenu(new_)
blank = GMenuItem("Empty file","empty")
push!(newsubmenu,blank)
template = GMenuItem("From template...","template")
push!(newsubmenu,template)
pushfirst!(filemenu, new_)
quit = GMenuItem("Quit","quit")
push!(filemenu, quit)
GLib.submenu(menubar,"File",filemenu)

mb = GtkPopoverMenuBar(menubar)
b = GtkBox(:h)
push!(b,mb)
win = GtkWindow(b, "Menus", 200, 40)
@test length(filemenu)==3
destroy(win)
end

