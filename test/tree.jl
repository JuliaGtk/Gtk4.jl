using Gtk4, Test

@testset "tree" begin

window = GtkWindow("GtkTree", 300, 100)
boxtop = GtkBox(:v) # vertical box, basic structure

wscroll = GtkScrolledWindow()

function itemlist(types, rownames)

    @assert length(types) == length(rownames)

    list = GtkTreeStore(types...)
    tv = GtkTreeView(GtkTreeModel(list))
    cols = GtkTreeViewColumn[]

    for i=1:length(types)
        r1 = GtkCellRendererText()
        c1 = GtkTreeViewColumn(rownames[i], r1, Dict([("text",i-1)]))
        Gtk4.sort_column_id(c1,i-1)
        push!(cols,c1)
        push!(tv,c1)
    end

    return (tv,list,cols)
end

tv::GtkTreeView, store, cols = itemlist([Int, String], ["No", "Name"])
treeModel = GtkTreeModel(store)

wscroll[] = tv
push!(boxtop, wscroll)
push!(window, boxtop)

wscroll.height_request = 300

##

push!(store, (1, "London"))
iter = push!(store, (2, "Grenoble"))
iter2 = pushfirst!(store, (0, "Slough"))
deleteat!(store, iter2)

@test Gtk4.isvalid(store,iter)
@test Gtk4.ncolumns(treeModel) == 2

path = Gtk4.path(treeModel,iter)
@test depth(path) == 1
@test string(path) == "1"
@test prev(path)
@test string(path) == "0"

path2 = copy(path)
@test string(path2) == string(path)

next(path2)
@test string(path2) == "1"

path3 = GtkTreePath("1")
@test string(path3) == "1"
path3 !== nothing && down(path3)
@test string(path3) == "1:0"

path4 = GtkTreePath()

success, iter = Gtk4.iter(treeModel,path)
@test success == true
@test store[iter] == (1, "London")

iter = Gtk4.iter_from_string_index(store,"0")
@test Gtk4.isvalid(store,iter)
@test store[iter] == (1, "London")

iter = insert!(store, iter, (0,"Paris"); how = :sibling, where=:before)
@test store[iter] == (0,"Paris")

@test store[[1]] == (0,"Paris")

@test length(treeModel, iter) == 0
@test string(treeModel, iter) == "0"
@test index_from_iter(treeModel, iter) == [1]

iter = insert!(store, iter, (3,"Paris child"); how = :parent, where=:after)
path = Gtk4.path(treeModel,iter)
@test depth(path) == 2
@test depth(store, iter) == 1

expand_to_path(tv, path)

iter = insert!(store, [3], (4, "Barcelona"); how = :sibling, where=:after)
@test store[[4],2] == "Barcelona"
store[[4],2] = "Madrid"
splice!(store, [4])

## selection

selection = Gtk4.selection(tv)
@test hasselection(selection) == false

iter = Gtk4.iter_from_string_index(store,"0")
select!(selection, iter)

@test length(selection) == 1

iters = Gtk4.selected_rows(selection)
@test length(iters) == 1
@test store[iters[1],1] == 0

unselect!(selection, iter)
@test length(selection) == 0

empty!(store)
empty!(cols[1])

end
