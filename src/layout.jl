## GtkBox

function push!(b::GtkBox,w::GtkWidget)
    G_.append(b,w)
    b
end

function pushfirst!(b::GtkBox,w::GtkWidget)
    G_.prepend(b,w)
    b
end

## GtkGrid

function getindex(grid::GtkGrid, i::Integer, j::Integer)
    x = G_.get_child_at(grid, i-1, j-1)
    x === nothing && error("tried to get non-existent child at [$i $j]")
    return x
end

function setindex!(grid::GtkGrid, child, i::Union{T, AbstractRange{T}}, j::Union{R, AbstractRange{R}}) where {T <: Integer, R <: Integer}
    (rangestep(i) == 1 && rangestep(j) == 1) || throw(ArgumentError("cannot layout grid with range-step != 1"))
    G_.attach(grid, child, first(i)-1, first(j)-1, length(i), length(j))
end

## GtkFrame — A bin with a decorative frame and optional label

GtkFrame(label::AbstractString) = G_.Frame_new(label)
GtkFrame() = G_.Frame_new(nothing)

## GtkNotebook

GtkNotebook() = G_.Notebook_new()

function insert!(w::GtkNotebook, position::Integer, x::GtkWidget, label::Union{GtkWidget, AbstractString})
    G_.insert_page(w, x, label, position - 1) + 1
    w
end
function pushfirst!(w::GtkNotebook, x::GtkWidget, label::Union{GtkWidget, AbstractString})
    G_.prepend_page(w, x, label) + 1
    w
end
function push!(w::GtkNotebook, x::GtkWidget, label::Union{GtkWidget, AbstractString})
    if isa(label, AbstractString)
        label = G_.Label_new(label)
    end
    G_.append_page(w, x, label) + 1
    w
end
function splice!(w::GtkNotebook, i::Integer)
    G_.remove_page(w, i - 1)
    w
end

pagenumber(w::GtkNotebook, child::GtkWidget) =
    G_.page_num(w, child) + 1

length(w::GtkNotebook) = G_.get_n_pages(w)
