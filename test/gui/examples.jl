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

# currently failing on some arch's
if (Sys.iswindows() || Sys.WORD_SIZE!=64)
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
    @test Gtk4.G_.match(filt,Gtk4.GLib.G_.get_item(GListModel(model),0))
    destroy(win)
end

@testset "Sorted List View" begin
    include(joinpath(@__DIR__, "..", "..", "examples", "sortedlistview.jl"))
    @test Gtk4.G_.compare(sorter,Gtk4.GLib.G_.get_item(GListModel(model),0), Gtk4.GLib.G_.get_item(GListModel(model),1)) == -1
    destroy(win)
end

@testset "Column View" begin
    include(joinpath(@__DIR__, "..", "..", "examples", "columnview.jl"))
    destroy(win)
end

@testset "List View with TreeListModel" begin
    include(joinpath(@__DIR__, "..", "..", "examples", "filteredlistview_tree.jl"))
    @test match(Gtk4.G_.get_row(treemodel,0))
    destroy(win)
end

@testset "Listbox" begin
    include(joinpath(@__DIR__, "..", "..", "examples", "listbox.jl"))
    destroy(main_window)
end

    #@testset "Show Image" begin
    #    include(joinpath(@__DIR__, "..", "..", "examples", "show_image.jl"))
    #    destroy(win)
    #end

    @testset "CSS Style" begin
        include(joinpath(@__DIR__, "..", "..", "examples", "css-style.jl"))
    end

end
