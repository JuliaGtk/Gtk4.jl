using Test, Gtk4, Gtk4.GLib, Gtk4.G_, Gtk4.Gdk4

# For testing callbacks
activate(w::GtkWidget) = G_.activate(w)

@testset "Window" begin
w = GtkWindow("Window", 400, 300)

sleep(0.1) # allow the window to appear

if false && !Sys.iswindows()
    # On windows, the wrong screen sizes are reported
    @test width(w) == 400
    @test height(w) == 300
    @test size(w) == (400, 300)
    #wdth, hght = screen_size(w)
    #@test wdth > 0 && hght > 0
end
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
f = GtkFrame()
w = GtkWindow(f,
    "Frame", 400, 400)
f[] = GtkLabel("A boring widget")
@test f[].label == "A boring widget"
destroy(w)
end

@testset "Initially Hidden Canvas" begin
nb = GtkNotebook()
@test hasparent(nb)==false
vbox = GtkBox(:v)
c = GtkCanvas()
push!(nb, vbox, "A")
push!(nb, c, "B")
insert!(nb, 2, GtkLabel("Something in the middle"), "A*")
pushfirst!(nb, GtkLabel("Something at the beginning"), "First")
splice!(nb, 3)
w = GtkWindow(nb,"TestDataViewer",600,600)
@test parent(nb) == w
@test pagenumber(nb,c)==3
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
four = GtkLabel("fo_ur")
push!(nb, four, "tab _four")
@test pagenumber(nb, four) == 4
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
@test pw[1].label == "one"
@test pw[2]==pw2
@test_throws ErrorException pw[3]
@test_throws ErrorException pw[3] = GtkLabel("three")
pw2[1]=GtkButton("two")
pw2[2]=GtkButton()
pw2[2][]=GtkLabel("three")
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
#@test f[1]==g1

b11 = GtkButton("first")
push!(g1, b11)
b12 = GtkButton("second")
push!(g1, b12)
b21 = GtkButton("first")
b22 = GtkButton("second")
push!(g2, b22)
pushfirst!(g2, b21)

strs = ["first", "second"]
i = 1
for child in g1
    @test get_gtk_property(child,:label,AbstractString) == strs[i]
    @test toplevel(child) == w
    i += 1
end

## Now shrink window
destroy(w)
end

@testset "CenterBox" begin
    centerbox = GtkCenterBox(:v)
    centerbox[:start] = GtkLabel("start")
    centerbox[:center] = GtkLabel("center")
    centerbox[:end] = GtkLabel("end")
    @test_throws ErrorException centerbox[:below] = GtkLabel("below")

    @test centerbox[:start].label == "start"
    @test centerbox[:center].label == "center"
    @test centerbox[:end].label == "end"
    @test_throws ErrorException centerbox[:above] == "above"
end

@testset "Expander" begin
w = GtkWindow("Expander", 400, 400)
ex = GtkExpander("Some buttons")
b = GtkBox(:h)
ex[]=b
@test ex[]==b
push!(w, ex)
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
    insert!(grid,grid[1,2],Gtk4.Constants.PositionType_RIGHT)
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

@testset "Button with custom icon (& Pixbuf)" begin
icon = Matrix{GdkPixbufLib.RGB}(undef, 40, 20)
fill!(icon, GdkPixbufLib.RGB(0,0xff,0))
icon[5:end-5, 3:end-3] .= Ref(GdkPixbufLib.RGB(0,0,0xff))
pb=GdkPixbuf(data=icon, has_alpha=false)
@test eltype(pb) == GdkPixbufLib.RGB
@test size(pb) == (40, 20)
@test pb[1,1].g==0xff
pb[10,10]=GdkPixbufLib.RGB(0,0,0)
pb[20:30,1:5]=GdkPixbufLib.RGB(0xff,0,0)
im=GtkImage(pb)
bu=GtkButton(im)
w = GtkWindow(bu, "Icon button", 60, 40)
@test bu[]==im
pb2=copy(pb)
@test size(pb2,2) == size(pb)[2]
pb3=slice(pb2,11:20,11:20)
@test size(pb3) == (10,10)
fill!(pb3,GdkPixbufLib.RGB(0,0,0))
destroy(w)
end

@testset "Image and Picture" begin
img = GtkImage(; icon_name = "document-open")
p = GdkPaintable(img)
empty!(img)
pic = GtkPicture()
end

@testset "checkbox" begin
w = GtkWindow("Checkbutton")
check = GtkCheckButton("check me"); push!(w,check)
set_gtk_property!(check,:active,true)
@test get_gtk_property(check,:active,AbstractString) == "TRUE"
set_gtk_property!(check,:label,"new label")
@test get_gtk_property(check,:label,AbstractString) == "new label"
destroy(w)
end

@testset "switch and togglebutton" begin
switch = GtkSwitch(true)
w = GtkWindow(switch,"Switch")
toggle = GtkToggleButton("toggle me")
w[] = toggle
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
#b = GtkColorButton(Gdk4.G_.copy(Gdk4._GdkRGBA(0, 0.8, 1.0, 0.3)))
w = GtkWindow(b, "ColorButton", 50, 50)
#GAccessor.rgba(ColorChooser(b), GLib.mutable(Gtk.GdkRGBA(0, 0, 0, 0)))
destroy(w)
end


@testset "slider/scale" begin
sl = GtkScale(:v, 1:10)
w = GtkWindow(sl, "Scale")
G_.set_value(sl, 3)
push!(sl,π,:right,"pi")
push!(sl,-3,:left)
@test G_.get_value(sl) == 3
adj = GtkAdjustment(sl)
@test get_gtk_property(adj,:value,Float64) == 3
set_gtk_property!(adj,:upper,11)
empty!(sl)
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


@testset "Builder" begin
b=GtkBuilder(filename="test.glade")
widgets = [w for w in b]
@test length(widgets)==length(b)
@test length(b)==6
button = b["a_button"]
@test isa(button,GtkButton)
@test isa(b[1],GtkWidget)

@load_builder(b)

@test button == b["a_button"]

#@test_throws ErrorException b2 = Builder(;filename="test2.glade")

s = open("test.glade","r") do f
    read(f,String)
end
b3 = GtkBuilder(buffer = s)


end

@testset "Canvas & AspectFrame" begin
c = GtkCanvas()
f = GtkAspectFrame(0.5, 1, 0.5, false)
f[] = c
@test f[] == c
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
destroy(w)
end

@testset "SetCoordinates" begin
    cnvs = GtkCanvas(300, 280)
    draw(cnvs) do c
        set_coordinates(getgc(c), BoundingBox(0, 1, 0, 1))
    end
    win = GtkWindow(cnvs)
    # sleep(2.0)
    # mtrx = Gtk4.Cairo.get_matrix(getgc(cnvs))
#     @test mtrx.xx == 300
#     @test mtrx.yy == 280
#     @test mtrx.xy == mtrx.yx == mtrx.x0 == mtrx.y0 == 0
#     surf = Gtk.cairo_surface(cnvs)
#     #a = Gtk.allocation(cnvs)
#     #@test isa(a,Gtk.GdkRectangle)
end

@testset "File Chooser" begin
    dlg = GtkFileChooserDialog("Select file", nothing, Gtk4.Constants.FileChooserAction_OPEN,
                            (("_Cancel", Gtk4.Constants.ResponseType_CANCEL),
                             ("_Open", Gtk4.Constants.ResponseType_ACCEPT)))
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

selmodel = G_.get_selection(tv)
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

G_.set_mode(selmodel,Gtk4.Constants.SelectionMode_MULTIPLE)
selectall!(selmodel)
iters = Gtk4.selected_rows(selmodel)
@test length(iters) == 2
@test ls[iters[1],1] == 35
unselectall!(selmodel)

tmSorted=GtkTreeModelSort(ls)
#G_.set_model(tv,tmSorted)
G_.set_sort_column_id(GtkTreeSortable(tmSorted),0,Gtk4.Constants.SortType_ASCENDING)
it = convert_child_iter_to_iter(tmSorted,Gtk4.iter_from_index(ls, 1))
G_.set_mode(selmodel,Gtk4.Constants.SelectionMode_SINGLE)
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

@testset "overlay" begin
c = GtkCanvas()
o = GtkOverlay(c)
@test o[] == c
push!(o,GtkButton("Button"))
w = GtkWindow(o, "overlay")
destroy(w)
end

@testset "dialogs" begin

main_window = GtkWindow("Dialog example")

d = info_dialog("Here's some information",main_window)
show(d)
response(d,Integer(Gtk4.Constants.ResponseType_DELETE_EVENT))

function get_response(d,id)
    ans = (id == Gtk4.Constants.ResponseType_YES ? "yes" : "no")
    destroy(d)
end

d = ask_dialog("May I ask you a question?",main_window)
signal_connect(get_response,d,"response")
show(d)

response(d,Integer(Gtk4.Constants.ResponseType_YES))

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

if !Sys.iswindows()#filter fails on windows 7
    csvfilter3 = GtkFileFilter(; mimetype="text/csv")
    @test csvfilter3.name == "text/csv"
end

csvfilter4 = GtkFileFilter(; pattern="*.csv", mimetype="text/csv")
# Pattern takes precedence over mime-type, causing mime-type to be ignored
@test csvfilter4.name == "*.csv"
end

# include("../examples/dialogs.jl")
#
# activate(file_open_dialog_button)
# sleep(0.1)
# activate(file_save_dialog_button)
# sleep(0.1)
# activate(file_open_dialog_native_button)
# sleep(0.1)
# activate(file_save_dialog_native_button)
# sleep(0.1)
#
# destroy(main_window)

@testset "application" begin

app = GtkApplication("julia.gtk4.example",
        Gtk4.GLib.Constants.ApplicationFlags_FLAGS_NONE)

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
