using Gtk4

@testset "comboboxtext" begin

@testset "populate with push!" begin
    cbstr = GtkComboBoxText()
    push!(cbstr, "1", "abc")
    push!(cbstr, "2", "xyz")

    set_gtk_property!(cbstr, :active, 0)
    @test get_gtk_property(cbstr, "active-id", String) == "1"

    set_gtk_property!(cbstr, :active, 1)
    @test get_gtk_property(cbstr, "active-id", String) == "2"

    push!(cbstr, "def")

    cbsym = GtkComboBoxText()
    push!(cbsym, :a, "abc")
    push!(cbsym, :b, "xyz")

    set_gtk_property!(cbsym, :active, 0)
    @test get_gtk_property(cbsym, "active-id", String) == "a"

    set_gtk_property!(cbsym, :active, 1)
    @test get_gtk_property(cbsym, "active-id", String) == "b"

    ls = GtkListStore(cbsym)
    @test length(ls) == 2

    @test ls[1] == ("abc","a")
    @test ls[1,1] == "abc"

    pop!(ls)
    @test length(ls) == 1
end

@testset "populate with pushfirst!" begin
    cbstr = GtkComboBoxText()
    pushfirst!(cbstr, "1", "abc")
    pushfirst!(cbstr, "2", "xyz")

    set_gtk_property!(cbstr, :active, 0)
    @test get_gtk_property(cbstr, "active-id", String) == "2"

    set_gtk_property!(cbstr, :active, 1)
    @test get_gtk_property(cbstr, "active-id", String) == "1"

    pushfirst!(cbstr, "def")

    cbsym = GtkComboBoxText()
    pushfirst!(cbsym, :a, "abc")
    pushfirst!(cbsym, :b, "xyz")

    set_gtk_property!(cbsym, :active, 0)
    @test get_gtk_property(cbsym, "active-id", String) == "b"

    set_gtk_property!(cbsym, :active, 1)
    @test get_gtk_property(cbsym, "active-id", String) == "a"
end

@testset "populate with insert!" begin
    cbstr = GtkComboBoxText()
    push!(cbstr, "1", "abc")
    push!(cbstr, "3", "mno")
    insert!(cbstr, 2, "2", "xyz")

    set_gtk_property!(cbstr, :active, 0)
    @test get_gtk_property(cbstr, "active-id", String) == "1"

    set_gtk_property!(cbstr, :active, 1)
    @test get_gtk_property(cbstr, "active-id", String) == "2"

    set_gtk_property!(cbstr, :active, 2)
    @test get_gtk_property(cbstr, "active-id", String) == "3"

    insert!(cbstr, 3, "def")
    delete!(cbstr, 3)

    cbsym = GtkComboBoxText()
    push!(cbsym, :a, "abc")
    push!(cbsym, :c, "mno")
    insert!(cbsym, 2, :b, "xyz")

    set_gtk_property!(cbsym, :active, 0)
    @test get_gtk_property(cbsym, "active-id", String) == "a"

    set_gtk_property!(cbsym, :active, 1)
    @test get_gtk_property(cbsym, "active-id", String) == "b"

    set_gtk_property!(cbsym, :active, 2)
    @test get_gtk_property(cbsym, "active-id", String) == "c"

    empty!(cbsym)
end


end
