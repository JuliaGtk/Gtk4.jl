using Test, Gtk4, Gtk4.GLib, Gtk4.G_, Gtk4.GdkPixbufLib, Cairo, ColorTypes

@testset "Labelframe" begin
f = GtkFrame("Label")
w = GtkWindow(f,"Labelframe", 400, 400)
destroy(w)
end

## Widgets

@testset "Button with custom icon (& Pixbuf)" begin
icon = Matrix{GdkPixbufLib.RGB}(undef, 40, 20)
fill!(icon, GdkPixbufLib.RGB(0,0xff,0))
icon[5:end-5, 3:end-3] .= Ref(GdkPixbufLib.RGB(0,0,0xff))
pb=GdkPixbuf(icon, false)
@test eltype(pb) == GdkPixbufLib.RGB
@test size(pb) == (40, 20)
@test pb[1,1].g==0xff
@test pb[1:2,1:2][1,1].g==0xff
@test GdkPixbufLib.bstride(pb,1) == 3
@test GdkPixbufLib.bstride(pb,2) == 3*40
@test GdkPixbufLib.bstride(pb,3) == 0
pb[10,10]=GdkPixbufLib.RGB(0,0,0)
pb[20:30,1:5]=GdkPixbufLib.RGB(0xff,0,0)
im=GtkImage(pb)
bu=GtkButton(im)
w = GtkWindow(bu, "Icon button", 60, 40)
@test bu[]==im
pb2=copy(pb)
if pb2!==nothing
    @test size(pb2,2) == size(pb)[2]
    pb3=slice(pb2,11:20,11:20)
    @test size(pb3) == (10,10)
    fill!(pb3,GdkPixbufLib.RGB(0,0,0))
end
destroy(w)
end

@testset "GLArea" begin
    glarea = GtkGLArea()
end

@testset "List view" begin

ls=GtkListStore(Int32,Bool)
push!(ls,(42,true))
ls[1,1]=44
push!(ls,(33,true))
pushfirst!(ls,(22,false))
popfirst!(ls)
@test size(ls)==(2,2)
insert!(ls, 2, (35, false))
tv=GtkTreeView(GtkTreeModel(ls))
r1=GtkCellRendererText()
r2=GtkCellRendererToggle()
c1=GtkTreeViewColumn("A", r1, Dict([("text",0)]))
c2=GtkTreeViewColumn("B", r2, Dict([("active",1)]))
push!(tv,c1)
push!(tv,c2)
delete!(tv, c1)
insert!(tv, 1, c1)
w = GtkWindow(tv, "List View")

## selection

selmodel = Gtk4.selection(tv)
@test hasselection(selmodel) == false
select!(selmodel, Gtk4.iter_from_index(ls, 1))
@test hasselection(selmodel) == true
iter = selected(selmodel)
@test Gtk4.index_from_iter(ls, iter) == 1
@test ls[iter, 1] == 44
deleteat!(ls, iter)
select!(selmodel, Gtk4.iter_from_index(ls, 1))
iter = selected(selmodel)
@test ls[iter, 1] == 35

Gtk4.mode(selmodel,Gtk4.SelectionMode_MULTIPLE)
selectall!(selmodel)
iters = Gtk4.selected_rows(selmodel)
@test length(iters) == 2
@test ls[iters[1],1] == 35
unselectall!(selmodel)

tmSorted=GtkTreeModelSort(ls)
#G_.set_model(tv,tmSorted)
G_.set_sort_column_id(GtkTreeSortable(tmSorted),0,Gtk4.SortType_ASCENDING)
it = convert_child_iter_to_iter(tmSorted,Gtk4.iter_from_index(ls, 1))
Gtk4.mode(selmodel,Gtk4.SelectionMode_SINGLE)
#select!(selmodel, it)
#iter = selected(selmodel)
#@test TreeModel(tmSorted)[iter, 1] == 35

empty!(ls)

destroy(w)

end

@testset "Tree view" begin
ts=GtkTreeStore(AbstractString)
iter1 = push!(ts,("one",))
iter2 = push!(ts,("two",),iter1)
iter3 = push!(ts,("three",),iter2)
tv=GtkTreeView(GtkTreeModel(ts))
r1=GtkCellRendererText()
c1=GtkTreeViewColumn("A", r1, Dict([("text",0)]))
push!(tv,c1)
w = GtkWindow(tv, "Tree View")
iter = Gtk4.iter_from_index(ts, [1])
ts[iter,1] = "ONE"
@test ts[iter,1] == "ONE"
@test map(i -> ts[i, 1], Gtk4.TreeIterator(ts, iter)) == ["two", "three"]
@test Gtk4.iter_n_children(GtkTreeModel(ts), iter)==1

pushfirst!(ts,("first child of two",),iter2)

destroy(w)
end

@testset "GdkRGBA" begin
    r=RGBA(1,0,0,0)
    q=convert(GdkRGBA,r)
    qs=unsafe_load(q.handle)
    @test red(r)==qs.red
    @test green(r)==qs.green
    @test blue(r)==qs.blue
    @test alpha(r)==qs.alpha
    
    rr=convert(RGBA,qs)
    @test red(r)==red(rr)
    @test green(r)==green(rr)
    @test blue(r)==blue(rr)
    @test alpha(r)==alpha(rr)
end

