module Gtk4TestModule
using Test

# An increasing number of tests are failing for x86, not sure why.

@testset "GLib" begin
if Sys.WORD_SIZE == 64
    include("keyfile.jl")
    include("misc.jl")
end
#include("date.jl")
include("datetime.jl")
#include("gstring.jl")
include("mainloop.jl")
include("list.jl")

include("gvalue.jl")

include("gfile.jl")
include("gmenu.jl")
include("action-group.jl")
end

@testset "Pango" begin
include("pango.jl")
end

@testset "GdkPixbuf" begin
include("gdkpixbuf.jl")
end

@testset "Graphene" begin
include("graphene.jl")
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
include("gui/examples.jl")
if VERSION <= v"1.12"
include("gui/application.jl")  # needs to be last because it messes with the main loop
end
end

GC.gc()

sleep(2)

end
