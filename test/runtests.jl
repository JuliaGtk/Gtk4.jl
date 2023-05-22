module Gtk4TestModule
using Test

@testset "GLib" begin
if Sys.WORD_SIZE == 64
    include("keyfile.jl")
    include("bytes.jl")
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
include("comboboxtext.jl")
include("tree.jl")
include("text.jl")
include("gui/dialogs.jl")
include("gui/layout.jl")
include("gui/examples.jl")
include("gui/application.jl")
end

GC.gc()

sleep(2)

end
