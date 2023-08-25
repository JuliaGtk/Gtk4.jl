using Test, Gtk4

@testset "Image and Picture" begin
# empty image
img = GtkImage()
p = Gtk4.paintable(img)
@test p === nothing
# named icon
img = Gtk4.G_.Image_new_from_icon_name("document-open")
p = Gtk4.paintable(img)
@test p === nothing
empty!(img)
pic = GtkPicture()
icon = Matrix{GdkPixbufLib.RGB}(undef, 40, 20)
fill!(icon, GdkPixbufLib.RGB(0,0xff,0))
icon[5:end-5, 3:end-3] .= Ref(GdkPixbufLib.RGB(0,0,0xff))
pb=GdkPixbuf(100, 100, false)
Gtk4.pixbuf(pic, pb)
pic2 = GtkPicture(pb)

texture = GdkTexture(pb)
@test width(texture)==100
@test height(texture)==100

# test ambiguous constructor handling
@test_throws ErrorException GtkPicture(nothing)
@test_throws ErrorException GtkImage(nothing)
@test_throws ErrorException GtkVideo(nothing)
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

@testset "Statusbar" begin
vbox = GtkBox(:v)
w = GtkWindow(vbox, "Statusbar")
sb = GtkStatusbar()
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
