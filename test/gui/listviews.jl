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

