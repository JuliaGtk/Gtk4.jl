using Test, Gtk4.Graphene

@testset "point" begin
point = GraphenePoint()
Graphene.G_.init(point, 1.0, 2.0)
point2 = GraphenePoint()
Graphene.G_.init(point2, 1.0, 2.0)
@test Graphene.G_.equal(point,point2)
end

