using Test, Gtk4

@testset "List view" begin
win = GtkWindow("Listview demo")
sw = GtkScrolledWindow()
push!(win, sw)

model = GtkStringList(["Apple","Orange","Kiwi"])
push!(model, "Mango")
factory = GtkSignalListItemFactory()

@test length(model) == 4
@test model[2]=="Orange"

l = [s for s in GLib.GListModel(model)]
@test length(l) == 4

function setup_cb(f, li)
    set_child(li,GtkLabel(""))
end

function bind_cb(f, li)
    text = li[].string
    label = get_child(li)
    label.label = text
end

list = GtkListView(GtkSelectionModel(GtkSingleSelection(GLib.GListModel(model))), factory)

signal_connect(setup_cb, factory, "setup")
signal_connect(bind_cb, factory, "bind")

sw[]=list
@test sw[] == list

deleteat!(model, 1)
@test model[1] == "Orange"
@test length(model) == 3
empty!(model)
@test length(model) == 0

destroy(win)

end
