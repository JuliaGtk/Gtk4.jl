function convert(::Type{Orientation}, x::Symbol)
    if x === :h
        Orientation_HORIZONTAL
    elseif x === :v
        Orientation_VERTICAL
    else
        error("can't convert $x to GtkOrientation")
    end
end

function convert(::Type{PositionType}, x::Symbol)
    if x === :left
        PositionType_LEFT
    elseif x === :right
        PositionType_RIGHT
    elseif x === :top
        PositionType_TOP
    elseif x === :bottom
        PositionType_BOTTOM
    else
        error("can't convert $x to GtkPositionType")
    end
end

## GtkBox

"""
    GtkBox(orientation::Symbol, spacing::Integer=0; kwargs...)

Create and return a `GtkBox` widget. The `orientation` argument can be `:h` for
horizontal, or `:v` for vertical. The `spacing` argument controls the spacing
between child widgets in pixels. Keyword arguments allow you to set GObject
properties.
"""
GtkBox(orientation::Symbol, spacing::Integer=0; kwargs...) = GtkBox(convert(Orientation, orientation), spacing; kwargs...)

function push!(b::GtkBox,w::GtkWidget)
    hasparent(w) && error("Widget already has a parent")
    G_.append(b,w)
    b
end

function pushfirst!(b::GtkBox,w::GtkWidget)
    hasparent(w) && error("Widget already has a parent")
    G_.prepend(b,w)
    b
end

function delete!(box::GtkBox, w::GtkWidget)
    G_.remove(box, w)
    box
end

function empty!(box::GtkBox)
    children=collect(box) # removing widgets disrupts the iterator
    for w in children
        G_.remove(box,w)
    end
    box
end

## GtkSeparator

GtkSeparator(orientation::Symbol; kwargs...) = GtkSeparator(convert(Orientation, orientation); kwargs...)

## GtkCenterBox

"""
    GtkCenterBox(orientation::Symbol; kwargs...)

Create and return a `GtkCenterBox` widget. The `orientation` argument can be
`:h` for horizontal, or `:v` for vertical. Keyword arguments allow you to set
GObject properties.
"""
function GtkCenterBox(orientation::Symbol; kwargs...)
    b = GtkCenterBox(;kwargs...)
    G_.set_orientation(GtkOrientable(b), convert(Orientation, orientation))
    b
end

function setindex!(b::GtkCenterBox, w::Union{Nothing,GtkWidget}, pos::Symbol)
    if pos === :start
        G_.set_start_widget(b,w)
    elseif pos === :center
        G_.set_center_widget(b,w)
    elseif pos === :end
        G_.set_end_widget(b,w)
    else
        error("invalid position")
    end
end

function getindex(b::GtkCenterBox, pos::Symbol)
    if pos === :start
        return G_.get_start_widget(b)
    elseif pos === :center
        return G_.get_center_widget(b)
    elseif pos === :end
        return G_.get_end_widget(b)
    else
        error("invalid position")
    end
end

## GtkPaned
"""
    GtkPaned(orientation::Symbol; kwargs...)

Create and return a `GtkPaned` widget. The `orientation` argument can be
`:h` for horizontal, or `:v` for vertical. Keyword arguments allow you to set
GObject properties.
"""
GtkPaned(orientation::Symbol; kwargs...) = GtkPaned(convert(Orientation, orientation); kwargs...)

function getindex(pane::GtkPaned, i::Integer)
    if i == 1
        x = G_.get_start_child(pane)
    elseif i == 2
        x = G_.get_end_child(pane)
    else
        error("tried to get pane $i of GtkPaned")
    end
    x === nothing && error("tried to get non-existent child at $i of GtkPaned")
    return x
end

function setindex!(pane::GtkPaned, child::Union{Nothing,GtkWidget}, i::Integer)
    if i == 1
        G_.set_start_child(pane, child)
    elseif i == 2
        G_.set_end_child(pane, child)
    else
        error("tried to set pane $i of GtkPaned")
    end
end

## GtkGrid

rangestep(r::AbstractRange) = step(r)
rangestep(::Integer) = 1

function getindex(grid::GtkGrid, i::Integer, j::Integer)
    x = G_.get_child_at(grid, i-1, j-1)
    x === nothing && error("tried to get non-existent child at [$i $j]")
    return x
end

function setindex!(grid::GtkGrid, child, i::Union{T, AbstractRange{T}}, j::Union{R, AbstractRange{R}}) where {T <: Integer, R <: Integer}
    (rangestep(i) == 1 && rangestep(j) == 1) || throw(ArgumentError("cannot layout grid with range-step != 1"))
    G_.attach(grid, child, first(i)-1, first(j)-1, length(i), length(j))
end

function insert!(grid::GtkGrid, i::Integer, side)
    side = convert(PositionType, side)
    if side == PositionType_LEFT
        G_.insert_column(grid, i - 1)
    elseif side == PositionType_RIGHT
        G_.insert_column(grid, i)
    elseif side == PositionType_TOP
        G_.insert_row(grid, i - 1)
    elseif side == PositionType_BOTTOM
        G_.insert_row(grid, i)
    end
    grid
end

function insert!(grid::GtkGrid, sibling, side)
    side = convert(PositionType, side)
    G_.insert_next_to(grid, sibling, side)
    grid
end

function delete!(grid::GtkGrid, w::GtkWidget)
    G_.remove(grid, w)
    grid
end

function deleteat!(grid::GtkGrid, i::Integer, rowcol::Symbol)
    if rowcol === :row
        G_.remove_row(grid, i-1)
    elseif rowcol === :col
        G_.remove_column(grid, i-1)
    else
        error(string("rowcol must be row or col, got ", rowcol))
    end
    grid
end

function empty!(grid::GtkGrid)
    while (w = G_.get_first_child(grid)) !== nothing
        G_.remove(grid, w)
    end
    grid
end

function query_child(grid::GtkGrid, w::GtkWidget)
    parent(w) != grid && error("GtkWidget is not a child of GtkGrid.")
    col, row, w, h = G_.query_child(grid,w)
    (col + 1, row + 1, w, h)
end

## GtkFrame — A decorative frame and optional label

"""
    GtkFrame(label=nothing; kwargs...)

Create a `GtkFrame`, a layout widget that can hold a single child widget, with
an optional string `label`. Keyword arguments allow you to set GObject
properties.
"""
GtkFrame(;kwargs...) = GtkFrame(nothing; kwargs...)
"""
    GtkFrame(w::GtkWidget, label=nothing; kwargs...)

Create a `GtkFrame` with an optional string `label` and add `w` as its child.
Keyword arguments allow you to set GObject properties.
"""
function GtkFrame(w::GtkWidget, label=nothing; kwargs...)
    f = GtkFrame(label; kwargs...)
    f[] = w
    f
end

setindex!(f::GtkFrame, w::Union{Nothing,GtkWidget}) = G_.set_child(f,w)
getindex(f::GtkFrame) = G_.get_child(f)

## GtkAspectFrame - A widget that preserves the aspect ratio of its child

setindex!(f::GtkAspectFrame, w::Union{Nothing,GtkWidget}) = G_.set_child(f,w)
getindex(f::GtkAspectFrame) = G_.get_child(f)

## GtkExpander

setindex!(f::GtkExpander, w::Union{Nothing,GtkWidget}) = G_.set_child(f,w)
getindex(f::GtkExpander) = G_.get_child(f)

## GtkNotebook

function insert!(w::GtkNotebook, position::Integer, x::GtkWidget, label::Union{GtkWidget, AbstractString})
    if isa(label, AbstractString)
        label = G_.Label_new(label)
    end
    G_.insert_page(w, x, label, position - 1) + 1
    w
end
function pushfirst!(w::GtkNotebook, x::GtkWidget, label::Union{GtkWidget, AbstractString})
    if isa(label, AbstractString)
        label = G_.Label_new(label)
    end
    G_.prepend_page(w, x, label) + 1
    w
end
function push!(w::GtkNotebook, x::GtkWidget, label::AbstractString)
    widget = G_.Label_new(label)
    G_.append_page(w, x, widget) + 1
    w
end
function push!(w::GtkNotebook, x::GtkWidget, label::GtkWidget)
    G_.append_page(w, x, label) + 1
    w
end

function splice!(w::GtkNotebook, i::Integer)
    G_.remove_page(w, i - 1)
    w
end
function deleteat!(w::GtkNotebook, i::Integer)
    G_.remove_page(w, i - 1)
    w
end

pagenumber(w::GtkNotebook, child::GtkWidget) =
    G_.page_num(w, child) + 1

length(w::GtkNotebook) = G_.get_n_pages(w)

function empty!(w::GtkNotebook)
    while G_.get_n_pages(w) > 0
        G_.remove_page(w,0)
    end
    w
end

## GtkOverlay

"""
    GtkOverlay(w=nothing; kwargs...)

Create a `GtkOverlay`, a layout widget that holds one main child and other
child "overlay" widgets that are drawn on top of the main child. The main child
can be set using the argument `w`.
"""
function GtkOverlay(w::GtkWidget; kwargs...)
    o = GtkOverlay(; kwargs...)
    o[] = w
    o
end

setindex!(f::GtkOverlay, w::Union{Nothing,GtkWidget}) = G_.set_child(f,w)
getindex(f::GtkOverlay) = G_.get_child(f)

function add_overlay(f::GtkOverlay, x::GtkWidget, clip_overlay=false, measure_overlay=false)
    G_.add_overlay(f,x)
    clip_overlay && G_.set_clip_overlay(f,x,true)
    measure_overlay && G_.set_measure_overlay(f,x,true)
end
remove_overlay(f::GtkOverlay, x::GtkWidget) = G_.remove_overlay(f,x)
set_clip_overlay(f::GtkOverlay, x::GtkWidget, b::Bool) = G_.set_clip_overlay(f,x,b)
set_measure_overlay(f::GtkOverlay, x::GtkWidget, b::Bool) = G_.set_measure_overlay(f,x,b)

## GtkStack

push!(s::GtkStack, x::GtkWidget) = (G_.add_child(s,x); s)
push!(s::GtkStack, x::GtkWidget, name::AbstractString) = (G_.add_named(s,x,name); s)
push!(s::GtkStack, x::GtkWidget, name::AbstractString, title::AbstractString) = (G_.add_titled(s,x,name,title); s)
getindex(s::GtkStack, name::AbstractString) = G_.get_child_by_name(s,name)
setindex!(s::GtkStack, x::GtkWidget, name::AbstractString) = G_.add_named(s,x,name)
delete!(s::GtkStack, x::GtkWidget) = (G_.remove(s,x); s)

function empty!(s::GtkStack)
    while (w = G_.get_first_child(s)) !== nothing
        G_.remove(s,w)
    end
    s
end

## GtkPopover

getindex(w::GtkPopover) = G_.get_child(w)
setindex!(w::GtkPopover, c::GtkWidget) = G_.set_child(w,c)
popup(m::GtkPopover) = G_.popup(m)

