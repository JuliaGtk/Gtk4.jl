using Test, Gtk4

@testset "Examples" begin

@testset "CSS" begin
    include(joinpath(@__DIR__, "..", "..", "examples", "css.jl"))
    activate(b2)
    sleep(0.5)
    activate(b)
    sleep(0.25)
    destroy(win)
end

@testset "Calculator" begin
    include(joinpath(@__DIR__, "..", "..", "examples", "calculator4.jl"))
    destroy(win)
end

@testset "List View" begin
    include(joinpath(@__DIR__, "..", "..", "examples", "listview.jl"))
    destroy(win)
end

if !(get(ENV, "CI", nothing) == "true" && Sys.iswindows())
@testset "GL Area" begin
    include(joinpath(@__DIR__, "..", "..", "examples", "glarea.jl"))
    destroy(w)
end
end

@testset "Cairo canvas" begin
    include(joinpath(@__DIR__, "..", "..", "examples", "canvas.jl"))
    destroy(win)
end

@testset "Dialogs" begin
    include(joinpath(@__DIR__, "..", "..", "examples", "dialogs.jl"))
    destroy(main_window)
end

@testset "Filtered List View" begin
    include(joinpath(@__DIR__, "..", "..", "examples", "filteredlistview.jl"))
    @test Gtk4.G_.match(filter,Gtk4.GLib.G_.get_item(GListModel(model),0))
    destroy(win)
end

@testset "Sorted List View" begin
    include(joinpath(@__DIR__, "..", "..", "examples", "sortedlistview.jl"))
    @test Gtk4.G_.compare(sorter,Gtk4.GLib.G_.get_item(GListModel(model),0), Gtk4.GLib.G_.get_item(GListModel(model),1))
    destroy(win)
end

@testset "Listbox" begin
    include(joinpath(@__DIR__, "..", "..", "examples", "listbox.jl"))
    destroy(main_window)
end

end
