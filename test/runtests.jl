module Gtk4TestModule
using Test

if Sys.islinux()
@testset "GLib" begin
include("keyfile.jl")
include("date.jl")
include("datetime.jl")
include("bytes.jl")
#include("gstring.jl")
include("mainloop.jl")
include("list.jl")

include("gvalue.jl")
#include("gbinding.jl")

include("gfile.jl")
include("gmenu.jl")
include("action-group.jl")
end
end

@testset "Pango" begin
include("families.jl")
include("layout.jl")
end

@testset "GdkPixbuf" begin
include("gdkpixbuf.jl")
end

@testset "Gtk" begin
include("gui.jl")
include("comboboxtext.jl")
include("tree.jl")
end

GC.gc()

sleep(2)

end
