using Gtk4, Gtk4.GLib

const entry = GtkSearchEntry()

# create root model (list of modules)
const modules = filter(x->!endswith(x.first.name, "_jll"),Base.loaded_modules)
const model = GtkStringList(string.(names(Gtk4)))

# create tree model (names under modules)
rootmodel = GtkStringList([x.first.name for x in modules])

const ks = collect(keys(modules))

function create_model(obj)
    if obj.string in [x.first.name for x in modules]
        mod = modules[ks[findfirst(x->x.name == obj.string, ks)]]
        modnames = [join([obj.string, string(n)], ".") for n in names(mod)]
        modelValues = GtkStringList(modnames)
        GLib.glib_ref(modelValues)
        return modelValues.handle
    else
        return C_NULL
    end
end

const treemodel = GtkTreeListModel(GListModel(rootmodel),false, true, create_model)

# create factory for list view
function get_funcname(text)  # faster than split(text,'.')[end]
    i=findfirst('.',text)
    if i !== nothing
        return @views text[(i+1):end]
    end
    return text
end

function setup_cb(f, li)
    tree_expander = GtkTreeExpander()
    set_child(tree_expander,GtkLabel(""))
    set_child(li,tree_expander)
end

function bind_cb(f, li)
    row = li[]
    tree_expander = get_child(li)
    Gtk4.set_list_row(tree_expander, row)
    text = Gtk4.G_.get_string(Gtk4.get_item(row))
    label = get_child(tree_expander)
    Gtk4.label(label, get_funcname(text))
end

factory = GtkSignalListItemFactory(setup_cb, bind_cb)

# set up filtering
function matchstr(str, ent)
    i=findfirst('.',str)
    if i !== nothing
        sstr = @views str[(i+1):end]
        return startswith(sstr, ent)
    else
        return startswith(str, ent)
    end
end
matchstr(str, ::Nothing) = true
matchchildren(cren, ent) = any(x->matchstr(x, ent), cren)

function match(row::GtkTreeListRow)
    entrytext = Gtk4.text(GtkEditable(entry))
    if entrytext == "" || entrytext === nothing
        return true
    end
    item = Gtk4.get_item(row)
    if item === nothing
        return false
    end
    text = Gtk4.G_.get_string(item)
    thismatch = matchstr(text, entrytext)
    if thismatch
        return true
    end
    cren = Gtk4.get_children(row)
    if cren !== nothing && !thismatch  # check children
        return matchchildren(cren, entrytext)  # return true if any children match
    end
    return false
end

filt = GtkCustomFilter(match)
filteredModel = GtkFilterListModel(GListModel(treemodel), filt)

# create listview
selmodel = GtkSelectionModel(GtkSingleSelection(GListModel(filteredModel)))
list = GtkListView(selmodel, factory; vexpand=true)

# connect to filter
signal_connect(entry, :search_changed) do w
  @idle_add changed(filt, Gtk4.FilterChange_DIFFERENT) 
end

win = GtkWindow("Listview tree demo with filter",600,800)
win[] = box = GtkBox(:v)
push!(box, entry)
sw = GtkScrolledWindow()
push!(box, sw)
sw[] = list
