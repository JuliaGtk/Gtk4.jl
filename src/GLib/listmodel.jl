function GListStore(t)
    t = g_type_from_name(Symbol(t))
    t == 0 && error("Invalid GType")
    G_.ListStore_new(t)
end

push!(ls::GListStore, item) = (G_.append(ls, item); ls)
pushfirst!(ls::GListStore, item) = (G_.insert(ls, 0, item); ls)
insert!(ls::GListStore, i::Integer, item) = (G_.insert(ls, i-1, item); ls)
empty!(ls::GListStore) = (G_.remove_all(ls); ls)
deleteat!(ls::GListStore, i::Integer) = (G_.remove(ls, i-1);ls)

length(ls::GListStore) = length(GListModel(ls))
getindex(ls::GListStore, i::Integer) = getindex(GListModel(ls),i)
iterate(ls::GListStore, i=0) = (i==length(ls) ? nothing : (getindex(ls, i+1),i+1))
eltype(::Type{GListStore}) = GObject
Base.keys(lm::GListStore) = Base.OneTo(length(lm))
Base.lastindex(lm::GListStore) = length(lm)

show(io::IO, ls::GListStore) = show(io, GListModel(ls), GListStore)

## GListModel interface
length(lm::GListModel) = G_.get_n_items(lm)
getindex(lm::GListModel, i::Integer) = G_.get_item(lm,i - 1)
iterate(lm::GListModel, i=0) = (i==length(lm) ? nothing : (getindex(lm, i+1),i+1))
eltype(::Type{GListModel}) = GObject
Base.keys(lm::GListModel) = 1:length(lm)
Base.lastindex(lm::GListModel) = length(lm)

function _get_screenheight(io)
    if !(get(io, :limit, false)::Bool)
        return typemax(Int)
    else
        sz = displaysize(io)::Tuple{Int,Int}
        return sz[1] - 4
    end
end

function show(io::IO, lm::GListModel, t = GListModel)
    l=length(lm)
    if l>0
        screenheight = _get_screenheight(io)
        halfheight = div(screenheight,2)
        print(io, l)
        println(io, "-element $t:")
        if l<= screenheight
            for el in lm
                print(" ")
                print(IOContext(io, :compact=>true), el)
                if el != last(lm)
                    println(io)
                end
            end
        else
            for i in 1:halfheight-1
                print(" ")
                println(IOContext(io, :compact=>true), lm[i])
            end
            println(" \u22ee")
            for i in l - halfheight+1:l
                print(" ")
                print(IOContext(io, :compact=>true), lm[i])
                if i!=l
                    println(io)
                end
            end
        end
    else
        println(io, "0-element GListModel")
    end
end
