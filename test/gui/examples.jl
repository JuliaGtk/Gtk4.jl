using Test, Gtk4

@testset "CSS" begin
    include(joinpath(@__DIR__, "..", "..", "examples", "css.jl"))
    activate(b2)
    sleep(0.5)
    activate(b)
end
