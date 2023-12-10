module HDF5Viewer

using Gtk4, HDF5, Gtk4.GLib

if Threads.nthreads() == 1 && Threads.nthreads(:interactive) < 1
    @warn("For a more responsive UI, run with multiple threads enabled.")
end

export hdf5view

# This is really just a toy at this point, but it is a less trivial example of
# using a ListView to show a tree and it uses a second thread to keep the UI
# responsive.


# Ideas for improvements:
# - style: color rows by type (group, data)
# - context menu that allows you to copy the key of an item (so you can paste it somewhere)
# - filter by type
# - replace TreeView for attributes with a ListView

_repr(d::HDF5.Dataset) = repr(MIME("text/plain"),read(d), context=:limit=>true)
_repr(d::HDF5.Group) = ""

# setup callback for the key ColumnView (the first column)
function setup_cb(f, li)
    tree_expander = GtkTreeExpander()
    set_child(tree_expander,GtkLabel(""))
    set_child(li,tree_expander)
end

# setup callback for the type and size ColumnViews
list_setup_cb(f, li) = set_child(li,GtkLabel(""))

# bind callback for the key ColumnView
function bind_cb(f, li)
    row = li[]
    tree_expander = get_child(li)
    Gtk4.set_list_row(tree_expander, row)
    text = Gtk4.get_item(row).string
    text = split(text,'/')[end]
    label = get_child(tree_expander)
    label.label = text
end

# Build tree model from an HDF5 file

lmm(g,k) = GtkStringList([join([k,b],'/') for b in keys(g)])
lmm(d::HDF5.Dataset,k) = nothing

function create_tree_model(filename)
    h5open(filename,"r") do h
        function create_model(pp)
            k=pp.string::String
            return lmm(h[k],k)
        end
        rootmodel = GtkStringList(keys(h))
        GtkTreeListModel(GLib.GListModel(rootmodel),false, true, create_model)
    end
end

# Print data in a TextView

function render_data(dtv,txt,atv,ls,pr)
    if ls === nothing
        hide(atv)
        Gtk4.position(pr,0)
    else
        Gtk4.model(atv,GtkTreeModel(ls))
        show(atv)
        Gtk4.position(pr,100)
    end
    dtv.buffer.text = txt
end

function match_string(row, entrytext)
    item = Gtk4.get_item(row)
    if item === nothing
        return false
    end
    if contains(Gtk4.G_.get_string(item), entrytext)
        return true
    end
    # if any of this row's children match, we should show this one too
    cren = Gtk4.get_children(row)
    if cren !== nothing
        for i=0:(length(cren)-1)
            if match_string(Gtk4.G_.get_child_row(row,i), entrytext)
                return true
            end
        end
    end
    return false
end

function hdf5view(filename::AbstractString)
    ispath(filename) || error("Path $filename does not exist")
    isfile(filename) || error("File not found")
    HDF5.ishdf5(filename) || error("File is not HDF5")
    b = GtkBuilder(joinpath(@__DIR__, "HDF5Viewer.ui"))
    w = b["win"]::GtkWindowLeaf
    Gtk4.title(w, "HDF5 Viewer: $filename")
    treemodel = create_tree_model(filename)

    factory = GtkSignalListItemFactory(setup_cb, bind_cb)

    # bind callback for the type ColumnView
    function type_bind_cb(f, li)
        label = get_child(li)
        row = li[]
        k=Gtk4.get_item(row).string
        h5open(filename,"r") do h
            d=h[k]
            if isa(d,HDF5.Group)
                Gtk4.label(label, "Group")
            else
                eltyp=string(HDF5.get_jl_type(d))
                Gtk4.label(label, "Array{$eltyp}")
            end
        end
    end

    # bind callback for the size ColumnView
    function size_bind_cb(f, li)
        label = get_child(li)
        row = li[]
        k=Gtk4.get_item(row).string
        h5open(filename,"r") do h
            d=h[k]
            if isa(d,HDF5.Group)
                n=length(d)
                label.label = n!=1 ? "$n objects" : "1 object"
            else
                label.label = repr(size(d))
            end
        end
    end

    type_factory = GtkSignalListItemFactory(list_setup_cb, type_bind_cb)
    size_factory = GtkSignalListItemFactory(list_setup_cb, size_bind_cb)
    
    search_entry = b["search_entry"]::GtkSearchEntryLeaf  # controls the filter
    spinner = b["spinner"]::GtkSpinnerLeaf  # spins during possibly long render operations
    
    function match(row::GtkTreeListRow)
        entrytext = Gtk4.text(GtkEditable(search_entry))
        if entrytext == "" || entrytext === nothing
            return true
        end
        match_string(row, entrytext)
    end
    
    filt = GtkCustomFilter(match)
    filteredModel = GtkFilterListModel(GListModel(treemodel), filt)

    single_sel = GtkSingleSelection(GLib.GListModel(filteredModel))
    sel = GtkSelectionModel(single_sel)
    list = b["list"]::GtkColumnViewLeaf
    name_column = b["name_column"]::GtkColumnViewColumnLeaf
    Gtk4.factory(name_column,factory)
    type_column = b["type_column"]::GtkColumnViewColumnLeaf
    Gtk4.factory(type_column,type_factory)
    size_column = b["size_column"]::GtkColumnViewColumnLeaf
    Gtk4.factory(size_column,size_factory)

    Gtk4.model(list,sel)

    pr = b["paned2"]::GtkPanedLeaf

    atv = b["atv"]
    dtv = b["dtv"]::GtkTextViewLeaf

    function on_selected_changed(selection, position, n_items)
        position = Gtk4.G_.get_selected(selection)
        row = Gtk4.G_.get_row(treemodel,position)
        row!==nothing || return
        p = Gtk4.get_item(row).string
        start(spinner)
        Threads.@spawn h5open(filename,"r") do h
            d=h[p]

            # show attributes
            a=attributes(d)
            ls = if length(a)>0
                ls=GtkListStore(String, String)
                for ak in keys(a)
                    push!(ls,(ak,string(read(a[ak]))))
                end
                ls
            else
                nothing
            end

            str = _repr(d)
            @idle_add begin
                render_data(dtv,str,atv,ls,pr)
                stop(spinner)
            end
        end
    end

    signal_connect(on_selected_changed,sel,"selection_changed")

    signal_connect(search_entry, "search-changed") do widget
        @idle_add changed(filt, Gtk4.FilterChange_DIFFERENT)
    end
    show(w)
    
    @idle_add on_selected_changed(single_sel, 0, 1)

    nothing
end

end # module
