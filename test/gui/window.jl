using Test, Gtk4, Gtk4.G_

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
close(w)
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

@testset "WindowGroup" begin
    wg=GtkWindowGroup()
    w1 = GtkWindow("window 1")
    w2 = GtkWindow("window 2")
    push!(wg,w1)
    push!(wg,w2)
    delete!(wg,w1)
    delete!(wg,w2)
    destroy(w1)
    destroy(w2)
end
