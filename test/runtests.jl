module Gtk4TestModule
using Test, Gtk4, Gtk4.GLib

GLib.start_main_loop()

@testset "Pango" begin
include("pango.jl")
end

@testset "GdkPixbuf" begin
include("gdkpixbuf.jl")
end

@testset "Gtk" begin
include("gui.jl")
include("comboboxtext.jl")
include("tree.jl")
include("text.jl")
include("gui/misc.jl")
include("gui/canvas.jl")
include("gui/dialogs.jl")
include("gui/displays.jl")
include("gui/input.jl")
include("gui/layout.jl")
include("gui/window.jl")
include("gui/listviews.jl")

#include("gui/examples.jl")
#include("gui/application.jl")  # needs to be last because it messes with the main loop
end

GC.gc()

sleep(2)

end
