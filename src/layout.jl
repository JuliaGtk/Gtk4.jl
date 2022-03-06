function convert(::Type{Gtk4.Constants.Orientation}, x::Symbol)
    if x === :h
        Gtk4.Constants.Orientation_HORIZONTAL
    elseif x === :v
        Gtk4.Constants.Orientation_VERTICAL
    else
        error("can't convert $x to GtkOrientation")
    end
end

## GtkBox

GtkBox(orientation, spacing=0) = G_.Box_new(convert(Gtk4.Constants.Orientation, orientation), spacing)

function push!(b::GtkBox,w::GtkWidget)
    G_.append(b,w)
    b
end

function pushfirst!(b::GtkBox,w::GtkWidget)
    G_.prepend(b,w)
    b
end

### GtkPaned
GtkPaned(orientation) = G_.Paned_new(convert(Gtk4.Constants.Orientation, orientation))

function getindex(pane::GtkPaned, i::Integer)
    if i == 1
        x = G_.get_start_child(pane)
    elseif i == 2
        x = G_.get_end_child(pane)
    else
        error("tried to get pane $i of GtkPane")
    end
    x === nothing && error("tried to get non-existent child at $i of GtkPane")
    return x
end

function setindex!(pane::GtkPaned, child, i::Integer)
    if i == 1
        G_.set_start_child(pane, child)
    elseif i == 2
        G_.set_end_child(pane, child)
    else
        error("tried to set pane $i of GtkPane")
    end
end

## GtkGrid

rangestep(r::AbstractRange) = step(r)
rangestep(::Integer) = 1

GtkGrid() = G_.Grid_new()

function getindex(grid::GtkGrid, i::Integer, j::Integer)
    x = G_.get_child_at(grid, i-1, j-1)
    x === nothing && error("tried to get non-existent child at [$i $j]")
    return x
end

function setindex!(grid::GtkGrid, child, i::Union{T, AbstractRange{T}}, j::Union{R, AbstractRange{R}}) where {T <: Integer, R <: Integer}
    (rangestep(i) == 1 && rangestep(j) == 1) || throw(ArgumentError("cannot layout grid with range-step != 1"))
    G_.attach(grid, child, first(i)-1, first(j)-1, length(i), length(j))
end

function insert!(grid::GtkGrid, i::Integer, side::Symbol)
    if side == :left
        G_.insert_column(grid, i - 1)
    elseif side == :right
        G_.insert_column(grid, i)
    elseif side == :top
        G_.insert_row(grid, i - 1)
    elseif side == :bottom
        G_.insert_row(grid, i)
    else
        error(string("invalid GtkPositionType ", s))
    end
end

function insert!(grid::GtkGrid, sibling, side::Symbol)
    pos=getfield(GtkPositionType,Symbol(uppercase(string(side))))
    G_.insert_next_to(grid, sibling, pos)
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
