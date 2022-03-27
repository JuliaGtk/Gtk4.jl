GtkComboBox() = G_.ComboBox_new()

setindex!(f::GtkComboBox, w::GtkWidget) = G_.set_child(f,w)
getindex(f::GtkComboBox) = G_.get_child(f)

GtkComboBoxText(with_entry::Bool = false) =
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

empty!(cb::GtkComboBoxText) = G_.remove_all(cb)

delete!(cb::GtkComboBoxText, i::Integer) = (G_.remove(cb, i-1); cb)

## GtkStringList

GtkStringList(list = nothing) = G_.StringList_new(list)
push!(sl::GtkStringList, str) = (G_.append(sl, str); sl)
getindex(sl::GtkStringList, i::Integer) = G_.get_string(sl, i - 1)

## GtkListView and GtkGridView

GtkListView(model=nothing, factory=nothing) = G_.ListView_new(model, factory)
GtkGridView(model=nothing, factory=nothing) = G_.GridView_new(model, factory)

GtkSignalListItemFactory() = G_.SignalListItemFactory_new()
GtkSingleSelection(model) = G_.SingleSelection_new(model)

getindex(li::GtkListItem) = G_.get_item(li)
set_child(li::GtkListItem, w) = G_.set_child(li, w)
get_child(li::GtkListItem) = G_.get_child(li)
