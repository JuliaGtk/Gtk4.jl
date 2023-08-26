using Gtk4, Gtk4.GLib, Test

@testset "List view" begin
win = GtkWindow("Listview demo")
sw = GtkScrolledWindow()
push!(win, sw)

slist0 = GtkStringList()
@test length(slist0) == 0

slist = GtkStringList(["Apple","Orange","Kiwi"])
model = GLib.GListModel(slist)
push!(slist, "Mango")
factory = GtkSignalListItemFactory()

@test length(slist) == 4
@test slist[2]=="Orange"

l = [s for s in model]
@test length(l) == 4

function setup_cb(f, li)
    set_child(li,GtkLabel(""))
end

function bind_cb(f, li)
    text = li[].string
    label = get_child(li)
    label.label = text
end


list = GtkListView(GtkSelectionModel(GtkSingleSelection(model)), factory)

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

@testset "Listbox" begin
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

destroy(win)

end
