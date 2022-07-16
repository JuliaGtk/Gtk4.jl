function GListStore(t)
    t = g_type_from_name(Symbol(t))
    t == 0 && error("Invalid GType")
    G_.ListStore_new(t)
end

push!(ls::GListStore, item) = (G_.append(ls, item); ls)
empty!(ls::GListStore) = G_.remove_all(ls)
deleteat!(ls::GListStore, i::Integer) = (G_.remove(ls, i-1);ls)

length(ls::GListStore) = length(GListModel(ls))
getindex(ls::GListStore, i::Integer) = getindex(GListModel(ls),i)
iterate(ls::GListStore, i=0) = (i==length(ls) ? nothing : (getindex(ls, i+1),i+1))
eltype(::Type{GListStore}) = GObject
Base.keys(lm::GListStore) = 1:length(lm)

length(lm::GListModel) = G_.get_n_items(lm)
getindex(lm::GListModel, i::Integer) = G_.get_item(lm,i - 1)
iterate(lm::GListModel, i=0) = (i==length(lm) ? nothing : (getindex(lm, i+1),i+1))
eltype(::Type{GListModel}) = GObject
Base.keys(lm::GListModel) = 1:length(lm)
