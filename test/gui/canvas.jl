using Test, Gtk4, Cairo

@testset "Canvas, AspectFrame, and event controllers" begin
c = GtkCanvas(100,100)
f = GtkAspectFrame(0.5, 1, 0.5, false)
f[] = c
@test f[] == c
gm = GtkEventControllerMotion(c)
gs = GtkEventControllerScroll(Gtk4.EventControllerScrollFlags_VERTICAL,c)
gk = GtkEventControllerKey(c)
ggc = GtkGestureClick(c)
ggd = GtkGestureDrag(c)
    gsc = GtkShortcutController(c)
    Gtk4.add_action_shortcut(gsc,"<Control>S","win.copy")
ggz = GtkGestureZoom(c)
t = Gtk4.find_controller(c,GtkEventControllerMotion)
@test t==gm
@test widget(gm) == c

delete!(c, gk)
t = Gtk4.find_controller(c,GtkEventControllerKey)
@test t===nothing

drew = Ref(false)
resized = Ref(false)
c.draw = function(_)
    if isdefined(c,:back)
        ctx = Gtk4.getgc(c)
        set_source_rgb(ctx, 1.0, 0.0, 0.0)
        paint(ctx)
        drew[] = true
    end
end
gf = GtkEventControllerFocus(c)
w = GtkWindow(f, "Canvas")
draw(c)
sleep(0.5)
if Sys.WORD_SIZE == 64
    @test drew[]
    drew[]=false
    resize(c) do _
        resized[] = true
    end
    Gtk4.G_.set_content_width(c,200)
    sleep(0.1)
    @test resized[]
    @test drew[]
end
reveal(c)
destroy(w)
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
    destroy(win)
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

@testset "Canvas initialization" begin
# must provide a nonzero size to use `init_back`
@test_throws ErrorException c = GtkCanvas(0,0,true)
c = GtkCanvas(10,10,true)
@test isdefined(c,:back)
end

