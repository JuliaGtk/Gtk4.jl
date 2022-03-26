function GListStore(t)
    t = g_type_from_name(Symbol(t))
    t == 0 && error("Invalid GType")
    G_.ListStore_new(t)
end

push!(ls::GListStore, item) = (G_.append(ls, item); ls)
empty!(ls::GListStore) = G_.remove_all(ls)
deleteat!(ls::GListStore, i::Integer) = (G_.remove(ls, i-1);ls)

length(lm::GListModel) = G_.get_n_items(lm)
getindex(lm::GListModel, i::Integer) = G_.get_item(lm,i)
