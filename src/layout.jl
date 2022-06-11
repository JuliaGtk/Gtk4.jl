function convert(::Type{Gtk4.Orientation}, x::Symbol)
    if x === :h
        Gtk4.Orientation_HORIZONTAL
    elseif x === :v
        Gtk4.Orientation_VERTICAL
    else
        error("can't convert $x to GtkOrientation")
    end
end

function convert(::Type{Gtk4.PositionType}, x::Symbol)
    if x === :left
        Gtk4.PositionType_LEFT
    elseif x === :right
        Gtk4.PositionType_RIGHT
    elseif x === :top
        Gtk4.PositionType_TOP
    elseif x === :bottom
        Gtk4.Orientation_BOTTOM
    else
        error("can't convert $x to GtkPositionType")
    end
end

## GtkBox

GtkBox(orientation, spacing=0) = G_.Box_new(convert(Gtk4.Orientation, orientation), spacing)

function push!(b::GtkBox,w::GtkWidget)
    G_.append(b,w)
    b
end

function pushfirst!(b::GtkBox,w::GtkWidget)
    G_.prepend(b,w)
    b
end

## GtkCenterBox

GtkCenterBox() = G_.CenterBox_new()
function GtkCenterBox(orientation)
    b = GtkCenterBox()
    G_.set_orientation(GtkOrientable(b), convert(Gtk4.Orientation, orientation))
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
GtkPaned(orientation) = G_.Paned_new(convert(Gtk4.Orientation, orientation))

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

function setindex!(pane::GtkPaned, child::Union{Nothing,GtkWidget}, i::Integer)
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
        error(string("invalid GtkPositionType ", side))
    end
end

function insert!(grid::GtkGrid, sibling, side)
    G_.insert_next_to(grid, sibling, side)
end


## GtkFrame — A decorative frame and optional label

GtkFrame(label::AbstractString) = G_.Frame_new(label)
GtkFrame() = G_.Frame_new(nothing)

setindex!(f::GtkFrame, w::Union{Nothing,GtkWidget}) = G_.set_child(f,w)
getindex(f::GtkFrame) = G_.get_child(f)

## GtkAspectFrame - A widget that preserves the aspect ratio of its child

GtkAspectFrame(xalign, yalign, ratio, obey_child) = G_.AspectFrame_new(xalign, yalign, ratio, obey_child)

setindex!(f::GtkAspectFrame, w::Union{Nothing,GtkWidget}) = G_.set_child(f,w)
getindex(f::GtkAspectFrame) = G_.get_child(f)

## GtkExpander

GtkExpander(title::AbstractString) = G_.Expander_new(title)

setindex!(f::GtkExpander, w::Union{Nothing,GtkWidget}) = G_.set_child(f,w)
getindex(f::GtkExpander) = G_.get_child(f)

## GtkNotebook

GtkNotebook() = G_.Notebook_new()

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

## GtkOverlay
GtkOverlay() = G_.Overlay_new()
function GtkOverlay(w::GtkWidget)
    o = GtkOverlay()
    o[] = w
    o
end

setindex!(f::GtkOverlay, w::Union{Nothing,GtkWidget}) = G_.set_child(f,w)
getindex(f::GtkOverlay) = G_.get_child(f)

push!(f::GtkOverlay, x::GtkWidget) = (G_.add_overlay(f,x); f)

## GtkStack

GtkStack() = G_.Stack_new()
push!(s::GtkStack, x::GtkWidget) = (G_.add_child(s,x); s)
push!(s::GtkStack, x::GtkWidget, name::AbstractString) = (G_.add_named(s,x,name); s)
push!(s::GtkStack, x::GtkWidget, name::AbstractString, title::AbstractString) = (G_.add_titled(s,x,name,title); s)
getindex(s::GtkStack, name::AbstractString) = G_.get_child_by_name(s,name)
setindex!(s::GtkStack, name::AbstractString, x::GtkWidget) = G_.add_named(s,x,name)

GtkStackSwitcher() = G_.StackSwitcher_new()
stack(w::GtkStackSwitcher) = G_.get_stack(w)
stack(w::GtkStackSwitcher, s::GtkStack) = G_.set_stack(w,s)
