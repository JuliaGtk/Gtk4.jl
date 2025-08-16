## GtkComboBox

GtkComboBoxText(with_entry::Bool) =
    if with_entry
        G_.ComboBoxText_new_with_entry()
    else
        G_.ComboBoxText_new()
    end
push!(cb::GtkComboBoxText, text::AbstractString) = (G_.append_text(cb, text); cb)
pushfirst!(cb::GtkComboBoxText, text::AbstractString) = (G_.prepend_text(cb, text); cb)
insert!(cb::GtkComboBoxText, i::Integer, text::AbstractString) = (G_.insert_text(cb, i - 1, text); cb)

push!(cb::GtkComboBoxText, id::Union{AbstractString, Symbol}, text::AbstractString) = (G_.append(cb, id, text); cb)
pushfirst!(cb::GtkComboBoxText, id::Union{AbstractString, Symbol}, text::AbstractString) = (G_.prepend(cb, id, text); cb)
insert!(cb::GtkComboBoxText, i::Integer, id::Union{AbstractString, Symbol}, text::AbstractString) = (G_.insert(cb, i - 1, id, text); cb)

empty!(cb::GtkComboBoxText) = (G_.remove_all(cb); cb)

delete!(cb::GtkComboBoxText, i::Integer) = (G_.remove(cb, i-1); cb)

## GtkStringList

"""
    GtkStringList()

Create an empty `GtkStringList`, which implements the `GListModel` interface
and holds an array of strings.
"""
GtkStringList() = G_.StringList_new(nothing)
push!(sl::GtkStringList, str) = (G_.append(sl, str); sl)
deleteat!(sl::GtkStringList, i::Integer) = (G_.remove(sl, i-1); sl)
empty!(sl::GtkStringList) = (G_.splice(sl, 0, length(sl), nothing); sl)
length(sl::GtkStringList) = length(GListModel(sl))
Base.keys(sl::GtkStringList) = Base.OneTo(length(sl))
Base.lastindex(sl::GtkStringList) = length(sl)
iterate(ls::GtkStringList, i=0) = (i==length(ls) ? nothing : (getindex(ls, i+1),i+1))
getindex(sl::GtkStringList, i::Integer) = G_.get_string(sl, i - 1)
eltype(::Type{GtkStringList}) = String
getindex(sl::GtkStringList, bs::GtkBitset) = [sl[i] for i in bs]

function show(io::IO, sl::GtkStringList)
    l=length(sl)
    if l>0
        screenheight = GLib._get_screenheight(io)
        print(io, l)
        println(io, "-element GtkStringList:")
        if l <= screenheight
            for i in 1:l
                print(io," ")
                print(IOContext(io, :compact=>true), repr(sl[i]))
                if i<l
                    println(io)
                end
            end
        else
            halfheight = div(screenheight,2)
            for i in 1:halfheight-1
                print(io," ")
                println(IOContext(io, :compact=>true), repr(sl[i]))
            end
            println(io," \u22ee")
            for i in l - halfheight+1:l
                print(io," ")
                print(IOContext(io, :compact=>true), repr(sl[i]))
                if i!=l
                    println(io)
                end
            end
        end
    else
        print(io, "0-element GtkStringList")
    end
end
string(obj::GtkStringObject) = G_.get_string(obj)

## GtkDropdown

"""
    GtkDropDown(; kwargs...)

Create a dropdown widget with no model (and thus no options to selected). A
model can be added using `model`. Keyword arguments set GObject properties.
"""
GtkDropDown(; kwargs...) = GtkDropDown(nothing, nothing; kwargs...)
"""
    GtkDropDown(a::AbstractArray; kwargs...)

Create a dropdown widget with a `GtkStringList` as its model. The model will be
populated with the elements of `a` converted to strings. Keyword arguments set
GObject properties.
"""
function GtkDropDown(a::AbstractArray; kwargs...)
    dd = Gtk4.G_.DropDown_new_from_strings(string.(collect(a)))
    GLib.setproperties!(dd; kwargs...)
    dd
end
"""
    selected_string(d::GtkDropDown)

Get the currently selected item in a dropdown widget. This method assumes that
the widget's model is a `GtkStringList` or that items in the model have a
"string" property.
"""
selected_string(d::GtkDropDown) = G_.get_selected_item(d).string
"""
    selected_string!(d::GtkDropDown, s::AbstractString)

Set the selected item in a dropdown widget. This method assumes that the
widget's model is a `GtkStringList`.
"""
function selected_string!(d::GtkDropDown, s::AbstractString)
    sl = G_.get_model(d)
    isnothing(sl) && error("No model set in GtkDropDown")
    isa(sl, GtkStringList) || error("This method only works if the model is a GtkStringList")
    i = findfirst(==(s), sl)
    isnothing(i) && error("String not found in model")
    G_.set_selected(d, i-1)
end

## GtkListView and GtkGridView

"""
    GtkListView(model=nothing; kwargs...)

Create a `GtkListView` widget, optionally with a model. Keyword arguments set
GObject properties.
"""
GtkListView(model=nothing; kwargs...) = GtkListView(model, nothing; kwargs...)
"""
    GtkGridView(model=nothing; kwargs...)

Create a `GtkGridView` widget, optionally with a model. Keyword arguments set
GObject properties.
"""
GtkGridView(model=nothing; kwargs...) = GtkGridView(model, nothing; kwargs...)

function scroll_to(lv::Union{GtkListView,GtkGridView}, pos, flags = ListScrollFlags_NONE)
    G_.scroll_to(lv, pos - 1, flags, nothing)
end

GtkColumnView(; kwargs...) = GtkColumnView(nothing; kwargs...)

function scroll_to(cv::GtkColumnView, pos, flags::ListScrollFlags = ListScrollFlags_NONE)
    G_.scroll_to(cv, pos - 1, nothing, flags, nothing)
end

function scroll_to(cv::GtkColumnView, pos, column::GtkColumnViewColumn, flags::ListScrollFlags = ListScrollFlags_NONE)
    G_.scroll_to(cv, pos - 1, column, flags, nothing)
end

GtkColumnViewColumn(title=""; kwargs...) = GtkColumnViewColumn(title, nothing; kwargs...)
push!(cv::GtkColumnView, cvc::GtkColumnViewColumn) = (G_.append_column(cv,cvc); cv)

getindex(li::GtkListItem) = G_.get_item(li)
set_child(li::GtkListItem, w) = G_.set_child(li, w)
get_child(li::GtkListItem) = G_.get_child(li)

set_list_row(te::GtkTreeExpander, w) = G_.set_list_row(te, w)
set_child(te::GtkTreeExpander, w) = G_.set_child(te, w)
get_child(te::GtkTreeExpander) = G_.get_child(te)

get_item(trl::GtkTreeListRow) = G_.get_item(trl)
get_children(trl::GtkTreeListRow) = G_.get_children(trl)
getindex(trl::GtkTreeListRow, pos) = G_.get_child_row(trl, pos - 1)

function GtkTreeListModel(root, passthrough, autoexpand, create_func)
    rootlm = GListModel(root)
    create_cfunc = @cfunction(GtkTreeListModelCreateModelFunc, Ptr{GObject}, (Ptr{GObject},Ref{Function}))
    ref, deref = GLib.gc_ref_closure(create_func)
    GLib.glib_ref(rootlm)
    ret = ccall(("gtk_tree_list_model_new", libgtk4), Ptr{GObject}, (Ptr{GObject}, Cint, Cint, Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}), rootlm, passthrough, autoexpand, create_cfunc, ref, deref)
    GtkTreeListModelLeaf(ret, true)
end

getindex(tlm::GtkTreeListModel, pos) = G_.get_row(tlm, pos - 1)

"""
    GtkSignalListItemFactory(setup_cb, bind_cb)

Create a `GtkSignalListItemFactory` and immediately connect "setup" and "bind"
callback functions `setup_cb` and `bind_cb`, respectively.
"""
function GtkSignalListItemFactory(@nospecialize(setup_cb::Function), @nospecialize(bind_cb::Function))
    factory = GtkSignalListItemFactory()
    signal_connect(setup_cb, factory, "setup")
    signal_connect(bind_cb, factory, "bind")
    factory
end

# the GI-generated version of this is currently broken
function CompareDataFunc(a, b, user_data)
    item1 = convert(GObject, a, false)
    item2 = convert(GObject, b, false)
    f = user_data
    ret = f(item1, item2)
    convert(Cint, ret)
end

# enums in GTK are so...
Ordering(x::UInt32) = unsafe_trunc(Int16,0xffff)

## GtkListBox
setindex!(lb::GtkListBox, w::GtkWidget, i::Integer) = (G_.insert(lb, w, i - 1); lb[i])
getindex(lb::GtkListBox, i::Integer) = G_.get_row_at_index(lb, i - 1)

push!(lb::GtkListBox, w::GtkWidget) = (G_.append(lb, w); lb)
pushfirst!(lb::GtkListBox, w::GtkWidget) = (G_.prepend(lb, w); lb)
insert!(lb::GtkListBox, i::Integer, w::GtkWidget) = (G_.insert(lb, w, i - 1); lb)

#empty!(lb::GtkListBox) = (ccall(("gtk_list_box_remove_all", libgtk4), Nothing, (Ptr{GObject},), lb); lb)

delete!(lb::GtkListBox, w::GtkWidget) = (G_.remove(lb, w); lb)

function set_filter_func(lb::GtkListBox, match::Function)
    cfunc = @cfunction(GtkListBoxFilterFunc, Cint, (Ptr{GObject}, Ref{Function}))
    ref, deref = GLib.gc_ref_closure(match)
    ccall(("gtk_list_box_set_filter_func", libgtk4), Nothing, (Ptr{GObject}, Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}), lb, cfunc, ref, deref)
    return nothing
end
function set_filter_func(cf::GtkListBox, ::Nothing)
    ccall(("gtk_list_box_set_filter_func", libgtk4), Nothing, (Ptr{GObject}, Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}), cf, C_NULL, C_NULL, C_NULL)
end
function set_sort_func(cf::GtkListBox, compare::Function)
    cfunc = @cfunction(CompareDataFunc, Cint, (Ptr{GObject}, Ptr{GObject}, Ref{Function}))
    ref, deref = GLib.gc_ref_closure(compare)
    ccall(("gtk_list_box_set_sort_func", libgtk4), Nothing, (Ptr{GObject}, Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}), cf, cfunc, ref, deref)
end
function set_sort_func(cf::GtkListBox, ::Nothing)
    ccall(("gtk_list_box_set_sort_func", libgtk4), Nothing, (Ptr{GObject}, Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}), cf, C_NULL, C_NULL, C_NULL)
end

## GtkFlowBox
setindex!(fb::GtkFlowBox, w::GtkWidget, i::Integer) = (G_.insert(fb, w, i - 1); fb[i])
getindex(fb::GtkFlowBox, i::Integer) = G_.get_child_at_index(fb, i - 1)

push!(fb::GtkFlowBox, w::GtkWidget) = (G_.append(fb, w); fb)
pushfirst!(fb::GtkFlowBox, w::GtkWidget) = (G_.prepend(fb, w); fb)
insert!(fb::GtkFlowBox, i::Integer, w::GtkWidget) = (G_.insert(fb, w, i - 1); fb)

delete!(fb::GtkFlowBox, w::GtkWidget) = (G_.remove(fb, w); fb)

function set_filter_func(fb::GtkFlowBox, match::Function)
    cfunc = @cfunction(GtkFlowBoxFilterFunc, Cint, (Ptr{GObject}, Ref{Function}))
    ref, deref = GLib.gc_ref_closure(match)
    ccall(("gtk_flow_box_set_filter_func", libgtk4), Nothing, (Ptr{GObject}, Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}), fb, cfunc, ref, deref)
    return nothing
end
function set_filter_func(cf::GtkFlowBox, ::Nothing)
    ccall(("gtk_flow_box_set_filter_func", libgtk4), Nothing, (Ptr{GObject}, Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}), cf, C_NULL, C_NULL, C_NULL)
end
function set_sort_func(cf::GtkFlowBox, compare::Function)
    cfunc = @cfunction(CompareDataFunc, Cint, (Ptr{GObject}, Ptr{GObject}, Ref{Function}))
    ref, deref = GLib.gc_ref_closure(compare)
    ccall(("gtk_flow_box_set_sort_func", libgtk4), Nothing, (Ptr{GObject}, Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}), cf, cfunc, ref, deref)
end
function set_sort_func(cf::GtkFlowBox, ::Nothing)
    ccall(("gtk_flow_box_set_sort_func", libgtk4), Nothing, (Ptr{GObject}, Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}), cf, C_NULL, C_NULL, C_NULL)
end

## GtkCustomFilter

function GtkCustomFilter(match::Function)
    cfunc = @cfunction(GtkCustomFilterFunc, Cint, (Ptr{GObject},Ref{Function}))
    ref, deref = GLib.gc_ref_closure(match)
    ret = ccall(("gtk_custom_filter_new", libgtk4), Ptr{GObject}, (Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}), cfunc, ref, deref)
    GtkCustomFilterLeaf(ret, true)
end

function set_filter_func(cf::GtkCustomFilter, match::Function)
    cfunc = @cfunction(GtkCustomFilterFunc, Cint, (Ptr{GObject}, Ref{Function}))
    ref, deref = GLib.gc_ref_closure(match)
    ccall(("gtk_custom_filter_set_filter_func", libgtk4), Nothing, (Ptr{GObject}, Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}), cf, cfunc, ref, deref)
    return nothing
end
function set_filter_func(cf::GtkCustomFilter, ::Nothing)
    ccall(("gtk_custom_filter_set_filter_func", libgtk4), Nothing, (Ptr{GObject}, Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}), cf, C_NULL, C_NULL, C_NULL)
end

changed(cf::GtkCustomFilter, _change = FilterChange_DIFFERENT) = G_.changed(cf, _change)

## GtkCustomSorter

function GtkCustomSorter(compare::Function)
    cfunc = @cfunction(CompareDataFunc, Cint, (Ptr{GObject}, Ptr{GObject}, Ref{Function}))
    ref, deref = GLib.gc_ref_closure(compare)
    ret = ccall(("gtk_custom_sorter_new", libgtk4), Ptr{GObject}, (Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}), cfunc, ref, deref)
    GtkCustomSorterLeaf(ret, true)
end

function set_sort_func(cf::GtkCustomSorter, compare::Function)
    cfunc = @cfunction(CompareDataFunc, Cint, (Ptr{GObject}, Ptr{GObject}, Ref{Function}))
    ref, deref = GLib.gc_ref_closure(compare)
    ccall(("gtk_custom_sorter_set_sort_func", libgtk4), Nothing, (Ptr{GObject}, Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}), cf, cfunc, ref, deref)
end
function set_sort_func(cf::GtkCustomSorter, ::Nothing)
    ccall(("gtk_custom_sorter_set_sort_func", libgtk4), Nothing, (Ptr{GObject}, Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}), cf, C_NULL, C_NULL, C_NULL)
end

changed(cs::GtkCustomSorter, _change = FilterChange_DIFFERENT) = G_.changed(cs, _change)

## GtkBitset (used for multiple selection)

length(bs::GtkBitset) = Int(Gtk4.G_.get_size(bs))
Base.isempty(bs::GtkBitset) = Gtk4.G_.is_empty(bs)
function getindex(bs::GtkBitset, i::Integer)
    (i<1 || i> length(bs)) && error("Index $i is out of bounds")
    Gtk4.G_.get_nth(bs, i-1)+1
end
push!(bs::GtkBitset, val) = (Gtk4.G_.add(bs,val-1); bs)
iterate(bs::GtkBitset, i=0) = (i==length(bs) ? nothing : (getindex(bs, i+1),i+1))
eltype(::Type{GtkBitset}) = UInt

## GtkExpressions

function glib_ref(x::Ptr{GtkExpression})
    ccall((:gtk_expression_ref, libgtk4), Nothing, (Ptr{GtkExpression},), x)
end
function glib_unref(x::Ptr{GtkExpression})
    ccall((:gtk_expression_unref, libgtk4), Nothing, (Ptr{GtkExpression},), x)
end

function GtkConstantExpression(x)
    t=GLib.g_type(typeof(x))
    t == 0 && error("Failed to look up the GType of $x")
    G_.GtkConstantExpression(gvalue(x))
end

function GtkPropertyExpression(typ::Type,name::AbstractString)
    t=GLib.g_type(typ)
    t == 0 && error("Failed to look up the GType of $x")
    G_.GtkPropertyExpression(t, nothing, name)
end

function evaluate(e::GtkExpression, this=nothing)
    rgv=Ref(GLib.GValue())
    Gtk4.G_.evaluate(e, this, rgv)
    rgv[Any]
end
