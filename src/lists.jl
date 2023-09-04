## GtkComboBox

setindex!(f::GtkComboBox, w::Union{Nothing,GtkWidget}) = G_.set_child(f,w)
getindex(f::GtkComboBox) = G_.get_child(f)

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

GtkStringList() = G_.StringList_new(nothing)
push!(sl::GtkStringList, str) = (G_.append(sl, str); sl)
deleteat!(sl::GtkStringList, i::Integer) = (G_.remove(sl, i-1); sl)
empty!(sl::GtkStringList) = (G_.splice(sl, 0, length(sl), nothing); sl)
length(sl::GtkStringList) = length(GListModel(sl))
Base.keys(sl::GtkStringList) = Base.OneTo(length(sl))
iterate(ls::GtkStringList, i=0) = (i==length(ls) ? nothing : (getindex(ls, i+1),i+1))
getindex(sl::GtkStringList, i::Integer) = G_.get_string(sl, i - 1)
eltype(::Type{GtkStringList}) = String

## GtkDropdown

GtkDropDown(; kwargs...) = GtkDropDown(nothing, nothing; kwargs...)
function GtkDropDown(a::AbstractArray; kwargs...)
    dd = Gtk4.G_.DropDown_new_from_strings(string.(collect(a)))
    GLib.setproperties!(dd; kwargs...)
    dd
end
selected_string(d::GtkDropDown) = G_.get_selected_item(d).string
function selected_string!(d::GtkDropDown, s::AbstractString)
    sl = G_.get_model(d)
    isa(sl, GtkStringList) || error("This method only works if the model is a GtkStringList")
    i = findfirst(==(s), sl)
    isnothing(i) && error("String not found in model")
    G_.set_selected(d, i-1)
end

## GtkListView and GtkGridView

GtkListView(model=nothing; kwargs...) = GtkListView(model, nothing; kwargs...)
GtkGridView(model=nothing; kwargs...) = GtkGridView(model, nothing; kwargs...)

GtkColumnView(; kwargs...) = GtkColumnView(nothing; kwargs...)
GtkColumnViewColumn(title=""; kwargs...) = GtkColumnViewColumn(title, nothing; kwargs...)
push!(cv::GtkColumnView, cvc::GtkColumnViewColumn) = (G_.append_column(cv,cvc); cv)

getindex(li::GtkListItem) = G_.get_item(li)
set_child(li::GtkListItem, w) = G_.set_child(li, w)
get_child(li::GtkListItem) = G_.get_child(li)

set_list_row(te::GtkTreeExpander, w) = G_.set_list_row(te, w)
set_child(te::GtkTreeExpander, w) = G_.set_child(te, w)
get_child(te::GtkTreeExpander) = G_.get_child(te)

get_item(trl::GtkTreeListRow) = G_.get_item(trl)

function GtkTreeListModel(root::GListModel, passthrough, autoexpand, create_func)
    create_cfunc = @cfunction(GtkTreeListModelCreateModelFunc, Ptr{GObject}, (Ptr{GObject},Ref{Function}))
    ref, deref = GLib.gc_ref_closure(create_func)
    ret = ccall(("gtk_tree_list_model_new", libgtk4), Ptr{GObject}, (Ptr{GObject}, Cint, Cint, Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}), root, passthrough, autoexpand, create_cfunc, ref, deref)
    convert(GtkTreeListModel, ret, true)
end

"""
    GtkSignalListItemFactory(setup_cb, bind_cb)

Create a `GtkSignalListItemFactory` and immediately connect "setup" and "bind" callback functions `setup_cb` and `bind_cb`, respectively.
"""
function GtkSignalListItemFactory(@nospecialize(setup_cb::Function), @nospecialize(bind_cb::Function))
    factory = GtkSignalListItemFactory()
    signal_connect(setup_cb, factory, "setup")
    signal_connect(bind_cb, factory, "bind")
    factory
end

## GtkListBox
setindex!(lb::GtkListBox, w::GtkWidget, i::Integer) = (G_.insert(lb, w, i - 1); lb[i])
getindex(lb::GtkListBox, i::Integer) = G_.get_row_at_index(lb, i - 1)

push!(lb::GtkListBox, w::GtkWidget) = (G_.append(lb, w); lb)
pushfirst!(lb::GtkListBox, w::GtkWidget) = (G_.prepend(lb, w); lb)
insert!(lb::GtkListBox, i::Integer, w::GtkWidget) = (G_.insert(lb, w, i - 1); lb)

#empty!(lb::GtkListBox) = (ccall(("gtk_list_box_remove_all", libgtk4), Nothing, (Ptr{GObject},), lb); lb)

delete!(lb::GtkListBox, w::GtkWidget) = (G_.remove(lb, w); lb)

function set_filter_func(lb::GtkListBox, match::Function)
    create_cfunc = @cfunction($match, Cint, (Ptr{GObject}, Ptr{Nothing}))
    ccall(("gtk_list_box_set_filter_func", libgtk4), Nothing, (Ptr{GObject}, Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}), lb, create_cfunc, C_NULL, C_NULL)
    return nothing
end


## GtkCustomFilter

function GtkCustomFilter(match::Function)
    create_cfunc = @cfunction($match, Cint, (Ptr{GObject}, Ptr{Nothing}))
    ret = ccall(("gtk_custom_filter_new", libgtk4), Ptr{GObject}, (Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}), create_cfunc, C_NULL, C_NULL)
    convert(GtkCustomFilter, ret, true)
end

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
