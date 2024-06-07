module HDF5Viewer

using Gtk4, HDF5, Gtk4.GLib
using PrecompileTools

export hdf5view

const rprogbar = Ref{GtkProgressBarLeaf}()

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

function create_tree_model(filename, pwin)
    treemodel = h5open(filename,"r") do h
        ks = keys(h)
        rootmodel = GtkStringList(ks)
        function create_model(pp)
            k=Gtk4.G_.get_string(pp)
            return lmm(h[k],k)
        end
        GtkTreeListModel(GLib.GListModel(rootmodel),false, true, create_model)
    end
    @idle_add begin
        Gtk4.destroy(pwin)
        _create_gui(filename, treemodel)
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

_render_type(d) = "Array{$(string(HDF5.get_jl_type(d)))}"
_render_type(d::HDF5.Group) = "Group"
_render_size(d) = repr(size(d))
_render_size(d::HDF5.Group) = length(d)!=1 ? "$(length(d)) objects" : "1 object"

function hdf5view(filename::AbstractString)
    ispath(filename) || error("Path $filename does not exist")
    isfile(filename) || error("File not found")
    HDF5.ishdf5(filename) || error("File is not HDF5")
    pwin = GtkWindow("Opening $filename",600,100)
    rprogbar[] = GtkProgressBar()
    b=GtkBox(:v)
    push!(b, GtkLabel("Please wait..."))
    pwin[] = push!(b,rprogbar[])
    t = Threads.@spawn create_tree_model(filename, pwin)
    g_timeout_add(100) do
        Gtk4.pulse(rprogbar[])
        return !istaskdone(t)
    end
    nothing
end

function _create_filter(b)
    search_entry = b["search_entry"]::GtkSearchEntryLeaf  # controls the filter
    function match(row::GtkTreeListRow)
        entrytext = Gtk4.text(GtkEditable(search_entry))
        if entrytext == "" || entrytext === nothing
            return true
        end
        match_string(row, entrytext)
    end

    filt = GtkCustomFilter(match)
    signal_connect(search_entry, "search-changed") do widget
        @idle_add changed(filt, Gtk4.FilterChange_DIFFERENT)
    end
    filt
end

function _create_gui(filename, treemodel)
    b = GtkBuilder(joinpath(@__DIR__, "HDF5Viewer.ui"))
    w = b["win"]::GtkWindowLeaf
    Gtk4.title(w, "HDF5 Viewer: $filename")
    
    factory = GtkSignalListItemFactory(setup_cb, bind_cb)

    # bind callback for the type ColumnView
    function type_bind_cb(f, li)
        label = get_child(li)::GtkLabelLeaf
        row = li[]::GtkTreeListRowLeaf
        k=Gtk4.G_.get_string(Gtk4.get_item(row))
        h5open(filename,"r") do h
            Gtk4.label(label, _render_type(h[k]))
        end
    end

    # bind callback for the size ColumnView
    function size_bind_cb(f, li)
        label = get_child(li)::GtkLabelLeaf
        row = li[]::GtkTreeListRowLeaf
        k=Gtk4.G_.get_string(Gtk4.get_item(row))
        h5open(filename,"r") do h
            Gtk4.label(label, _render_size(h[k]))
        end
    end

    type_factory = GtkSignalListItemFactory(list_setup_cb, type_bind_cb)
    size_factory = GtkSignalListItemFactory(list_setup_cb, size_bind_cb)
    
    spinner = b["spinner"]::GtkSpinnerLeaf  # spins during possibly long render operations
    
    filt = _create_filter(b)
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
        p = Gtk4.G_.get_string(Gtk4.get_item(row))
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

    show(w)
    
    @idle_add on_selected_changed(single_sel, 0, 1)

    nothing
end

function __init__()
    if Threads.nthreads() == 1 && Threads.nthreads(:interactive) < 1
        @warn("For a more responsive UI, run with multiple threads enabled.")
    end
end

let
    @setup_workload begin
        @compile_workload begin
            b = GtkBuilder(joinpath(@__DIR__, "HDF5Viewer.ui"))
            factory = GtkSignalListItemFactory(setup_cb, bind_cb)
            _create_filter(b)
        end
    end
end

end # module
