using Test, Gtk4

@testset "Examples" begin

@testset "CSS" begin
    include(joinpath(@__DIR__, "..", "..", "examples", "css.jl"))
    activate(b2)
    sleep(0.5)
    activate(b)
end

@testset "Calculator" begin
    include(joinpath(@__DIR__, "..", "..", "examples", "calculator4.jl"))
end

@testset "List View" begin
    include(joinpath(@__DIR__, "..", "..", "examples", "listview.jl"))
end

@testset "GL Area" begin
    include(joinpath(@__DIR__, "..", "..", "examples", "glarea.jl"))
end

@testset "Cairo canvas" begin
    include(joinpath(@__DIR__, "..", "..", "examples", "canvas.jl"))
end

@testset "Dialogs" begin
    include(joinpath(@__DIR__, "..", "..", "examples", "dialogs.jl"))
end
    
end
