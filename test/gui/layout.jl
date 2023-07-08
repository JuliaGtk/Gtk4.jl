using Test, Gtk4

@testset "Box" begin
    b = GtkBox(:v)
    l1 = GtkLabel("label1")
    l2 = GtkLabel("label2")
    push!(b, l1)
    push!(b, l2)
    delete!(b, l1)
    @test length([w for w in b]) == 1
end

@testset "Frame" begin
    f = GtkFrame()
    w = GtkWindow(f, "Frame", 400, 400)
    f[] = GtkLabel("A boring widget")
    @test f[].label == "A boring widget"
    destroy(w)
    l = GtkLabel("Another widget")
    f = GtkFrame(l)
    @test f[] == l
end

@testset "Grid" begin
    grid = GtkGrid()
    w = GtkWindow(grid,"Grid", 400, 400)
    for i=1:5, j=1:5
        b=GtkButton("$i,$j")
        grid[i,j] = b
        @test grid[i,j] == b
        col, row, wid, h = Gtk4.query_child(grid, b)
        @test col == i
        @test row == j
        @test wid == 1
        @test h == 1
    end
    deleteat!(grid,4,:row)
    deleteat!(grid,4,:col)
    @test_throws ErrorException insert!(grid,6,:above)
    @test_throws ErrorException deleteat!(grid,6,:below)

    tb = GtkButton("Tall button")
    grid[3,1:3] = tb
    delete!(grid, tb)
    insert!(grid,1,:top)
    insert!(grid,3,:bottom)
    insert!(grid,grid[1,2],Gtk4.PositionType_RIGHT)
    insert!(grid,1,:left)
    insert!(grid,2,:right)

    @test_throws ErrorException insert!(grid,1,:above)
    for w in grid
        println(w)
    end
    empty!(grid)
    destroy(w)
end

@testset "CenterBox" begin
    centerbox = GtkCenterBox(:v)
    centerbox[:start] = GtkLabel("start")
    centerbox[:center] = GtkLabel("center")
    centerbox[:end] = GtkLabel("end")
    @test_throws ErrorException centerbox[:below] = GtkLabel("below")

    @test centerbox[:start].label == "start"
    @test centerbox[:center].label == "center"
    @test centerbox[:end].label == "end"
    @test_throws ErrorException centerbox[:above] == "above"
end

@testset "Expander" begin
    w = GtkWindow("Expander", 400, 400)
    ex = GtkExpander("Some buttons")
    b = GtkBox(:h)
    ex[]=b
    @test ex[]==b
    push!(w, ex)
    destroy(w)
end

@testset "notebook" begin
    nb = GtkNotebook()
    w = GtkWindow(nb,"Notebook")
    push!(nb, GtkButton("o_ne"), "tab _one")
    push!(nb, GtkButton("t_wo"), "tab _two")
    push!(nb, GtkButton("th_ree"), "tab t_hree")
    four = GtkLabel("fo_ur")
    push!(nb, four, "tab _four")
    @test pagenumber(nb, four) == 4
    @test length(nb) == 4
    empty!(nb)
    @test length(nb) == 0
    destroy(w)
end

@testset "stack" begin
    b = GtkBox(:v)
    w = GtkWindow(b, "Stack")
    sw = GtkStackSwitcher()
    push!(b,sw)
    s = GtkStack()
    push!(b,s)
    Gtk4.stack(sw, s)
    @test Gtk4.stack(sw) == s
    push!(s,GtkLabel("Titled"),"titled","Titled")
    l2 = GtkLabel("Titled #1")
    push!(s, l2, "titled2", "Titled #2")
    @test s["titled2"] == l2
    l3 = GtkLabel("Named #1")
    push!(s,l3,"named1")
    @test s["named1"] == l3
    push!(s,GtkLabel("Just a child"))
    l4 = GtkLabel("Named #2")
    s["named2"] = l4
    @test s["named2"] == l4
    destroy(w)
end

@testset "overlay" begin
    c = GtkCanvas()
    o = GtkOverlay(c)
    @test o[] == c
    b=GtkButton("Button")
    add_overlay(o,b)
    w = GtkWindow(o, "overlay")
    remove_overlay(o,b)
    curs = GdkCursor("crosshair")
    cursor(c, curs)
    @test curs == cursor(c)
    destroy(w)
end

@testset "Panedwindow" begin
    pw = GtkPaned(:h)
    w = GtkWindow(pw,"Panedwindow", 400, 400)
    pw2 = GtkPaned(:v)
    pw[1]=GtkButton("one")
    pw[2]=pw2
    @test pw[1].label == "one"
    @test pw[2]==pw2
    @test_throws ErrorException pw[3]
    @test_throws ErrorException pw[3] = GtkLabel("three")
    pw2[1]=GtkButton("two")
    pw2[2]=GtkButton()
    pw2[2][]=GtkLabel("three")
    destroy(w)
end
