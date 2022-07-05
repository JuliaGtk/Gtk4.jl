"""
    parent(w::GtkWidget)

Returns the parent widget of `w`, or `nothing` if the widget has not been set as
the child of another widget (or is a toplevel widget, like a `GtkWindow`).
"""
parent(w::GtkWidget) = G_.get_parent(w)

"""
    hasparent(w::GtkWidget)

Returns `true` if `w` has a parent widget.
"""
hasparent(w::GtkWidget) = G_.get_parent(w) !== nothing

"""
    toplevel(w::GtkWidget)

Returns the topmost ancestor of `w`, which in most cases will be a `GtkWindow`.
"""
toplevel(w::GtkWidget) = G_.get_root(w)

"""
    width(w::GtkWidget)

Returns the allocated width of `w`.
"""
width(w::GtkWidget) = G_.get_allocated_width(w)

"""
    height(w::GtkWidget)

Returns the allocated height of `w`.
"""
height(w::GtkWidget) = G_.get_allocated_height(w)

size(w::GtkWidget) = (width(w), height(w))

"""
    isvisible(w::GtkWidget)

Returns whether `w` and all of its parents are marked as visible.
"""
isvisible(w::GtkWidget) = G_.is_visible(w)

"""
    visible(w::GtkWidget, state::Bool)

Control visibility of `w`. Note that `w` will not be visible unless its parent
is also visible.
"""
visible(w::GtkWidget, state::Bool) = G_.set_visible(w,state)

"""
    show(w::GtkWidget)

Flag `w` to be displayed and return `w`.
"""
function show(w::GtkWidget)
    G_.show(w)
    w
end

"""
    hide(w::GtkWidget)

Flag `w` to be hidden and return `w`. This is the opposite of `show`.
"""
hide(w::GtkWidget) = (G_.hide(w); w)

"""
    grab_focus(w::GtkWidget)

Gives `w` the keyboard focus for the window it is in. Returns `false` if this
fails.
"""
grab_focus(w::GtkWidget) = G_.grab_focus(w)

activate(w::GtkWidget) = G_.activate(w)

"""
    display(w::GtkWidget)

Gets the `GdkDisplay` for `w`. Should only be called if `w` has been added to
a widget hierarchy.
"""
display(w::GtkWidget) = G_.get_display(w)

"""
    monitor(w::GtkWidget)

Gets the `GdkMonitor` for `w`.
"""
function monitor(w::GtkWidget)
    d = display(w)
    tl = toplevel(w)
    tl === nothing && return nothing
    s = G_.get_surface(GtkNative(tl))
    Gdk4.G_.get_monitor_at_surface(d,s)
end

function cursor(w::GtkWidget, c::Union{Nothing,GdkCursor})
    G_.set_cursor(w, c)
end

function cursor(w::GtkWidget, n::AbstractString)
    G_.set_cursor_from_name(w, n)
end

function cursor(w::GtkWidget)
    G_.get_cursor(w)
end

function iterate(w::GtkWidget, state=nothing)
    next = (state === nothing ? G_.get_first_child(w) : G_.get_next_sibling(state))
    next === nothing ? nothing : (next, next)
end

eltype(::Type{GtkWidget}) = GtkWidget
IteratorSize(::Type{GtkWidget}) = Base.SizeUnknown()

convert(::Type{GtkWidget}, w::AbstractString) = GtkLabel(w)

## GtkApplication

GtkApplication(id = nothing, flags = GLib.ApplicationFlags_NONE) = G_.Application_new(id,flags)
push!(app::GtkApplication, win::GtkWindow) = G_.add_window(app, win)
menubar(app::GtkApplication, mb) = G_.set_menubar(app, mb)
