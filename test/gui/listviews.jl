using Gtk4, Gtk4.GLib, Test

@testset "List view" begin
win = GtkWindow("Listview demo")
sw = GtkScrolledWindow()
push!(win, sw)

slist0 = GtkStringList()
@test length(slist0) == 0
show(IOBuffer(), slist0)
show(IOBuffer(), GListModel(slist0))

slist = GtkStringList(["Apple","Orange","Kiwi"])
show(IOBuffer(), slist)
show(IOContext(IOBuffer(),:limit=>true,:displaysize=>(5,80)),slist)
model = GLib.GListModel(slist)
show(IOBuffer(), model)
show(IOContext(IOBuffer(),:limit=>true,:displaysize=>(5,80)),model)
push!(slist, "Mango")

@test length(slist) == 4
@test slist[2]=="Orange"
@test slist[end]=="Mango"

l = [s for s in model]
@test length(l) == 4

# test GtkStringObject by indexing using GListModel's methods
so1 = GListModel(slist)[1]
@test string(so1) == "Apple"

function setup_cb(f, li)
    set_child(li,GtkLabel(""))
end

function bind_cb(f, li)
    text = li[].string
    label = get_child(li)
    label.label = text
end

factory = GtkSignalListItemFactory()
list = GtkListView(GtkSelectionModel(GtkSingleSelection(model)))
Gtk4.factory(list,factory)

signal_connect(setup_cb, factory, "setup")
signal_connect(bind_cb, factory, "bind")

sw[]=list
@test sw[] == list

deleteat!(slist, 1)
@test slist[1] == "Orange"
@test length(slist) == 3
empty!(slist)
@test length(slist) == 0

destroy(win)

end

function match(item)
  label = item.child
  return startswith(label.label, "widget")
end

alpha_compare(item1, item2) = isless(item1.child.label, item2.child.label) ? -1 : 1

@testset "ListBox" begin
win = GtkWindow("ListBox demo with filter")
box = GtkBox(:v)
entry = GtkSearchEntry()
sw = GtkScrolledWindow()
push!(box, entry)
push!(box, sw)
push!(win, box)

listBox = GtkListBox()
l=GtkLabel("widget 1")
push!(listBox, l)
@test listBox[1].child == l
l0=GtkLabel("widget 0")
pushfirst!(listBox, l0)
@test listBox[1].child == l0
lmiddle=GtkLabel("widget 0.5")
insert!(listBox,2,lmiddle)
@test listBox[2].child == lmiddle

delete!(listBox, listBox[1])
@test listBox[2].child == l

listBox[1] = GtkLabel("widget 2")
@test listBox[2].child != l
sw[] = listBox
listBox.vexpand = true

Gtk4.set_filter_func(listBox, nothing)
Gtk4.set_sort_func(listBox, nothing)
Gtk4.set_sort_func(listBox, alpha_compare)

# while we're at it, test GtkExpression
pe = GtkPropertyExpression(GtkWindow, "title")
rgv=Ref(GLib.GValue())
Gtk4.G_.evaluate(pe, win, rgv)
#@test rgv[String] == "ListBox demo with filter"
#@test Gtk4.evaluate(pe, win) == "ListBox demo with filter"

ce = GtkConstantExpression(Gtk4.GLib.gvalue(3.0))
rgv[] = GValue()
Gtk4.G_.evaluate(ce, nothing, rgv)
@test rgv[Float64] == 3.0
@test Gtk4.evaluate(ce) == 3.0

destroy(win)

end

@testset "FlowBox" begin
win = GtkWindow("FlowBox demo with filter")
box = GtkBox(:v)
entry = GtkSearchEntry()
sw = GtkScrolledWindow()
push!(box, entry)
push!(box, sw)
push!(win, box)

listBox = GtkFlowBox()
l=GtkLabel("widget 1")
push!(listBox, l)
@test listBox[1].child == l
l0=GtkLabel("widget 0")
pushfirst!(listBox, l0)
@test listBox[1].child == l0
lmiddle=GtkLabel("widget 0.5")
insert!(listBox,2,lmiddle)
@test listBox[2].child == lmiddle

delete!(listBox, listBox[1])
@test listBox[2].child == l

listBox[1] = GtkLabel("widget 2")
@test listBox[2].child != l
sw[] = listBox
listBox.vexpand = true

Gtk4.set_filter_func(listBox, nothing)
Gtk4.set_sort_func(listBox, nothing)

Gtk4.set_filter_func(listBox, match)
Gtk4.set_sort_func(listBox, alpha_compare)

destroy(win)
end

@testset "GridView" begin
gridview = GtkGridView()
end

@testset "ColumnView" begin
columnview = GtkColumnView()
col = GtkColumnViewColumn("first column")
push!(columnview, col)
end

@testset "CustomFilter and CustomSorter" begin
filt = GtkCustomFilter(match)
Gtk4.set_filter_func(filt,nothing)
Gtk4.set_filter_func(filt,match)
Gtk4.changed(filt)

sorter = GtkCustomSorter(alpha_compare)
Gtk4.set_sort_func(sorter,nothing)
Gtk4.set_sort_func(sorter,alpha_compare)
Gtk4.changed(sorter)

end
