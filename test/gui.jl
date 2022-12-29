using Test, Gtk4, Gtk4.GLib, Gtk4.G_, Gtk4.GdkPixbufLib, Cairo

@testset "Window" begin

w = GtkWindow("Window", 400, 300)

# window doesn't acquire a width right away and there doesn't seem to be a way
# of finding this out, so we just wait
while width(w) == 0
    sleep(0.1)
end

@test width(w) == 400
@test height(w) == 300
wdth, hght = screen_size(w)
@test wdth > 0 && hght > 0

wdth, hght = screen_size()
@test wdth > 0 && hght > 0

visible(w,false)
@test isvisible(w) == false
visible(w,true)
@test isvisible(w) == true

m = Gtk4.monitor(w)
if m!==nothing
    r = Gtk4.G_.get_geometry(m)
end

#r2 = m.geometry

hide(w)
show(w)
grab_focus(w)

end

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
    @test w.title == nothing

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
    Gtk4.default_size(w, 200, 500)
    @test Gtk4.default_size(w) == (200, 500)
    destroy(w)
end

@testset "Window with HeaderBar" begin
    w = GtkWindow("Header bar", -1, -1, true, false) # need to add HeaderBar before showing the window
    hb = GtkHeaderBar()
    Gtk4.titlebar(w,hb)
    hb.show_title_buttons=false
    push!(hb,GtkLabel("end"))
    end2 = GtkLabel("end2")
    push!(hb,end2)
    delete!(hb,end2)
    pushfirst!(hb,GtkLabel("start"))
    Gtk4.title_widget(hb,GtkLabel("title widget"))
    show(w)
    present(w) # no need for this, just covers present()
    destroy(w)
end

@testset "Initially Hidden Canvas" begin
nb = GtkNotebook()
@test hasparent(nb)==false
vbox = GtkBox(:v)
c = GtkCanvas()
cursor(c,"crosshair")
push!(nb, vbox, "A")
push!(nb, c, "B")
insert!(nb, 2, GtkLabel("Something in the middle"), "A*")
pushfirst!(nb, GtkLabel("Something at the beginning"), "First")
splice!(nb, 3)
w = GtkWindow(nb,"TestDataViewer",600,600)
@test w[] == nb
@test parent(nb) == w
@test pagenumber(nb,c)==3
destroy(w)
end

@testset "Labelframe" begin
f = GtkFrame("Label")
w = GtkWindow(f,"Labelframe", 400, 400)
destroy(w)
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
b12 = GtkButton("second")
push!(g1, b12)
b21 = GtkButton("first")
b22 = GtkButton("second")
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

strs = ["first", "second"]
i = 1
for child in g1
    @test get_gtk_property(child,:label,AbstractString) == strs[i]
    @test toplevel(child) == w
    i += 1
end

destroy(w)
end

## Widgets

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

@testset "Button with custom icon (& Pixbuf)" begin
icon = Matrix{GdkPixbufLib.RGB}(undef, 40, 20)
fill!(icon, GdkPixbufLib.RGB(0,0xff,0))
icon[5:end-5, 3:end-3] .= Ref(GdkPixbufLib.RGB(0,0,0xff))
pb=GdkPixbuf(data=icon, has_alpha=false)
@test eltype(pb) == GdkPixbufLib.RGB
@test size(pb) == (40, 20)
@test pb[1,1].g==0xff
@test pb[1:2,1:2][1,1].g==0xff
@test GdkPixbufLib.bstride(pb,1) == 3
@test GdkPixbufLib.bstride(pb,2) == 3*40
@test GdkPixbufLib.bstride(pb,3) == 0
pb[10,10]=GdkPixbufLib.RGB(0,0,0)
pb[20:30,1:5]=GdkPixbufLib.RGB(0xff,0,0)
im=GtkImage(pb)
bu=GtkButton(im)
w = GtkWindow(bu, "Icon button", 60, 40)
@test bu[]==im
pb2=copy(pb)
if pb2!==nothing
    @test size(pb2,2) == size(pb)[2]
    pb3=slice(pb2,11:20,11:20)
    @test size(pb3) == (10,10)
    fill!(pb3,GdkPixbufLib.RGB(0,0,0))
end
destroy(w)
end

@testset "Image and Picture" begin
# empty image
img = GtkImage()
p = Gtk4.paintable(img)
@test p === nothing
# named icon
img = GtkImage(; icon_name = "document-open")
p = Gtk4.paintable(img)
@test p === nothing
empty!(img)
pic = GtkPicture()
icon = Matrix{GdkPixbufLib.RGB}(undef, 40, 20)
fill!(icon, GdkPixbufLib.RGB(0,0xff,0))
icon[5:end-5, 3:end-3] .= Ref(GdkPixbufLib.RGB(0,0,0xff))
pb=GdkPixbuf(width=100, height=100, has_alpha=false)
Gtk4.pixbuf(pic, pb)
pic2 = GtkPicture(pb)

texture = GdkTexture(pb)
@test width(texture)==100
@test height(texture)==100
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

end

@testset "togglebuttons in group" begin

w = GtkWindow("Togglebutton group test")
b = GtkBox(:v)
tb1 = GtkToggleButton("option 1")
tb2 = GtkToggleButton()
tb2.label = "option 2"
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

@testset "progressbar" begin
pb = GtkProgressBar()
w = GtkWindow(pb, "Progress bar")
set_gtk_property!(pb,:fraction,0.7)
@test get_gtk_property(pb,:fraction,Float64) == 0.7
@test fraction(pb) == 0.7
fraction(pb,0.8)
pulse_step(pb,0.1)
@test pulse_step(pb) == 0.1
pulse(pb)
destroy(w)
end

@testset "levelbar" begin
lb = GtkLevelBar(0,10)
Gtk4.value(lb,5)
@test Gtk4.value(lb)==5
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

@testset "Statusbar" begin
vbox = GtkBox(:v)
w = GtkWindow(vbox, "Statusbar")
global sb = GtkStatusbar()
push!(vbox, sb)
ctxid = Gtk4.context_id(sb, "Statusbar example")
bpush = GtkButton("push item")
bpop = GtkButton("pop item")
push!(vbox, bpush)
push!(vbox, bpop)
global sb_count = 1
id = signal_connect(bpush, "activate") do widget
    push!(sb, ctxid, string("Item ", sb_count))
    global sb_count += 1
end
id = signal_connect(bpop, "activate") do widget
    pop!(sb, ctxid)
end

activate(bpush)
activate(bpop)
empty!(sb,ctxid)
destroy(w)
end

@testset "Infobar" begin
infobar = GtkInfoBar()

end

# CSS

@testset "CssProviderLeaf(filename=\"...\")" begin
    style_file = joinpath(dirname(@__FILE__), "style_test.css")

    l = GtkLabel("I am some large blue text!")

    provider = GtkCssProvider(filename=style_file)

    sc = Gtk4.style_context(l)
    push!(sc, provider, 600)

    w = GtkWindow(l)
    show(w)

    ### add css tests here

    destroy(w)
end

@testset "Builder" begin
b=GtkBuilder(filename="test.ui")
widgets = [w for w in b]
@test length(widgets)==length(b)
@test length(b)==6
button = b["a_button"]
@test isa(button,GtkButton)
@test isa(b[1],GtkWidget)

@load_builder(b)

@test button == b["a_button"]

s = open("test.ui","r") do f
    read(f,String)
end
b3 = GtkBuilder(buffer = s)


end

@testset "Canvas & AspectFrame" begin
c = GtkCanvas()
f = GtkAspectFrame(0.5, 1, 0.5, false)
f[] = c
@test f[] == c
gm = GtkEventControllerMotion(c)
gs = GtkEventControllerScroll(Gtk4.EventControllerScrollFlags_VERTICAL,c)
gk = GtkEventControllerKey(c)
ggc = GtkGestureClick(c)
ggd = GtkGestureDrag(c)
ggz = GtkGestureZoom(c)
t = Gtk4.find_controller(c,GtkEventControllerMotion)
@test t==gm
@test widget(gm) == c
c.draw = function(_)
    if isdefined(c,:back)
        ctx = Gtk4.getgc(c)
        set_source_rgb(ctx, 1.0, 0.0, 0.0)
        paint(ctx)
    end
end
w = GtkWindow(f, "Canvas")
draw(c)
sleep(0.5)
reveal(c)
destroyed = Ref(false)
function test_destroy(w)
    destroyed[] = true
end
on_signal_destroy(test_destroy, c)
destroy(w)
#sleep(0.5)
#@test destroyed[] == true
end

@testset "SetCoordinates" begin
    cnvs = GtkCanvas(300, 280)
    sleep(0.2)
    draw(cnvs) do c
        set_coordinates(getgc(c), BoundingBox(0, 1, 0, 1))
    end
    win = GtkWindow(cnvs)
    sleep(1.0)
    s = size(cnvs)
    @test s[1] == 300
    @test s[2] == 280
    mtrx = Cairo.get_matrix(getgc(cnvs))
    @test mtrx.xx == 300
    @test mtrx.yy == 280
    @test mtrx.xy == mtrx.yx == mtrx.x0 == mtrx.y0 == 0
    surf = Gtk4.cairo_surface(cnvs)
end

@testset "GLArea" begin
    glarea = GtkGLArea()
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

@testset "File Chooser" begin
    dlg = GtkFileChooserDialog("Select file", nothing, Gtk4.FileChooserAction_OPEN,
                            (("_Cancel", Gtk4.ResponseType_CANCEL),
                             ("_Open", Gtk4.ResponseType_ACCEPT)))
    destroy(dlg)
end

@testset "List view" begin

ls=GtkListStore(Int32,Bool)
push!(ls,(42,true))
ls[1,1]=44
push!(ls,(33,true))
pushfirst!(ls,(22,false))
popfirst!(ls)
@test size(ls)==(2,2)
insert!(ls, 2, (35, false))
tv=GtkTreeView(GtkTreeModel(ls))
r1=GtkCellRendererText()
r2=GtkCellRendererToggle()
c1=GtkTreeViewColumn("A", r1, Dict([("text",0)]))
c2=GtkTreeViewColumn("B", r2, Dict([("active",1)]))
push!(tv,c1)
push!(tv,c2)
delete!(tv, c1)
insert!(tv, 1, c1)
w = GtkWindow(tv, "List View")

## selection

selmodel = Gtk4.selection(tv)
@test hasselection(selmodel) == false
select!(selmodel, Gtk4.iter_from_index(ls, 1))
@test hasselection(selmodel) == true
iter = selected(selmodel)
@test Gtk4.index_from_iter(ls, iter) == 1
@test ls[iter, 1] == 44
deleteat!(ls, iter)
select!(selmodel, Gtk4.iter_from_index(ls, 1))
iter = selected(selmodel)
@test ls[iter, 1] == 35

Gtk4.mode(selmodel,Gtk4.SelectionMode_MULTIPLE)
selectall!(selmodel)
iters = Gtk4.selected_rows(selmodel)
@test length(iters) == 2
@test ls[iters[1],1] == 35
unselectall!(selmodel)

tmSorted=GtkTreeModelSort(ls)
#G_.set_model(tv,tmSorted)
G_.set_sort_column_id(GtkTreeSortable(tmSorted),0,Gtk4.SortType_ASCENDING)
it = convert_child_iter_to_iter(tmSorted,Gtk4.iter_from_index(ls, 1))
Gtk4.mode(selmodel,Gtk4.SelectionMode_SINGLE)
#select!(selmodel, it)
#iter = selected(selmodel)
#@test TreeModel(tmSorted)[iter, 1] == 35

empty!(ls)

destroy(w)

end

@testset "Tree view" begin
ts=GtkTreeStore(AbstractString)
iter1 = push!(ts,("one",))
iter2 = push!(ts,("two",),iter1)
iter3 = push!(ts,("three",),iter2)
tv=GtkTreeView(GtkTreeModel(ts))
r1=GtkCellRendererText()
c1=GtkTreeViewColumn("A", r1, Dict([("text",0)]))
push!(tv,c1)
w = GtkWindow(tv, "Tree View")
iter = Gtk4.iter_from_index(ts, [1])
ts[iter,1] = "ONE"
@test ts[iter,1] == "ONE"
@test map(i -> ts[i, 1], Gtk4.TreeIterator(ts, iter)) == ["two", "three"]
@test Gtk4.iter_n_children(GtkTreeModel(ts), iter)==1

pushfirst!(ts,("first child of two",),iter2)

destroy(w)
end

@testset "List view" begin
win = GtkWindow("Listview demo")
sw = GtkScrolledWindow()
push!(win, sw)

model = GtkStringList(["Apple","Orange","Kiwi"])
push!(model, "Mango")
factory = GtkSignalListItemFactory()

@test length(model) == 4
@test model[2]=="Orange"

l = [s for s in GLib.GListModel(model)]
@test length(l) == 4

function setup_cb(f, li)
    set_child(li,GtkLabel(""))
end

function bind_cb(f, li)
    text = li[].string
    label = get_child(li)
    label.label = text
end

list = GtkListView(GtkSelectionModel(GtkSingleSelection(GLib.GListModel(model))), factory)

signal_connect(setup_cb, factory, "setup")
signal_connect(bind_cb, factory, "bind")

sw[]=list
@test sw[] == list

destroy(win)

end

@testset "keyval" begin
@test keyval("H") == Gtk4.KEY_H
end

@testset "FileFilter" begin
emptyfilter = GtkFileFilter()
@test get_gtk_property(emptyfilter, "name") === nothing
fname = "test.csv"
fdisplay = "test.csv"
fmime = "text/csv"
csvfilter1 = GtkFileFilter("*.csv")
@test csvfilter1.name == "*.csv"

csvfilter2 = GtkFileFilter("*.csv"; name="Comma Separated Format")
@test csvfilter2.name == "Comma Separated Format"

csvfilter3 = GtkFileFilter(; mimetype="text/csv")
@test csvfilter3.name == "text/csv"

csvfilter4 = GtkFileFilter(; pattern="*.csv", mimetype="text/csv")
# Pattern takes precedence over mime-type, causing mime-type to be ignored
@test csvfilter4.name == "*.csv"
end

@testset "application" begin

app = GtkApplication("julia.gtk4.example",
        Gtk4.GLib.ApplicationFlags_FLAGS_NONE)

Gtk4.GLib.stop_main_loop()  # g_application_run runs the loop and does other important stuff

function activate(app)
  window = GtkApplicationWindow(app, "GtkApplication example")

  function on_clicked(a,v)
    destroy(window)
  end

  function on_state_changed(a,v)
    Gtk4.GLib.set_state(a,v)
    b = v[Bool]
    @async println("state is now $b")
  end

  button_box = GtkBox(:v)
  push!(window, button_box)

  button = GtkButton("Click me to close the window")
  push!(button_box, button)
  button.action_name = "win.close"
  add_action(GActionMap(window),"close",on_clicked)

  toggle_button = GtkToggleButton("Toggle me")
  push!(button_box, toggle_button)
  toggle_button.action_name = "app.toggle"
  add_stateful_action(GActionMap(app), "toggle", false, on_state_changed)

  show(window)
end

Gtk4.signal_connect(activate, app, :activate)

loop()=Gtk4.run(app)
t = schedule(Task(loop))

end
