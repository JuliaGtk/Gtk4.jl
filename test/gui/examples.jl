using Test, Gtk4

@testset "Examples" begin

@testset "CSS" begin
    include(joinpath(@__DIR__, "..", "..", "examples", "css.jl"))
    activate(b2)
    sleep(0.5)
    activate(b)
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

@testset "GL Area" begin
    include(joinpath(@__DIR__, "..", "..", "examples", "glarea.jl"))
    destroy(w)
end

@testset "Cairo canvas" begin
    include(joinpath(@__DIR__, "..", "..", "examples", "canvas.jl"))
    destroy(win)
end

@testset "Dialogs" begin
    include(joinpath(@__DIR__, "..", "..", "examples", "dialogs.jl"))
    destroy(main_window)
end
    
end
