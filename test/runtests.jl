module Gtk4TestModule
using Test

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

@testset "Gtk" begin
include("gui.jl")
include("text.jl")
include("gui/misc.jl")
include("gui/layout.jl")
include("gui/displays.jl")
include("gui/input.jl")
include("gui/canvas.jl")
include("gui/window.jl")
include("gui/listview.jl")
include("gui/examples.jl")
include("gui/application.jl")
include("comboboxtext.jl")
include("tree.jl")
include("gui/dialogs.jl")
end

GC.gc()

sleep(2)

end
