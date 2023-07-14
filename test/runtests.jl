module Gtk4TestModule
using Test

const check_leaks = true

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

if !check_leaks
@testset "Pango" begin
include("pango.jl")
end
end

@testset "GdkPixbuf" begin
include("gdkpixbuf.jl")
end

@testset "Gtk" begin
if !check_leaks
include("gui.jl")
include("text.jl")
include("gui/layout.jl")
include("gui/examples.jl")
include("gui/application.jl")
end
include("comboboxtext.jl")
include("tree.jl")
include("gui/dialogs.jl")
end

GC.gc()

sleep(2)

end
