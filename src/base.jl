@doc """
    parent(w::GtkWidget)

Returns the parent widget of `w`, or `nothing` if the widget has not been set as
the child of another widget (or is a toplevel widget, like a `GtkWindow`).

See also [`toplevel`](@ref).

Related GTK function: [`gtk_widget_get_parent`()]($(gtkdoc_method_url("gtk4","Widget","get_parent")))
""" parent

"""
    hasparent(w::GtkWidget) -> Bool

Returns `true` if `w` has a parent widget.

See also [`parent`](@ref).
"""
hasparent(w::GtkWidget) = G_.get_parent(w) !== nothing

"""
    toplevel(w::GtkWidget)

Returns the topmost ancestor of `w`, which in most cases will be a `GtkWindow`.

See also [`parent`](@ref).

Related GTK function: [`gtk_widget_get_root`()]($(gtkdoc_method_url("gtk4","Widget","get_root")))
"""
toplevel(w::GtkWidget) = G_.get_root(w)

@doc """
    width(w::GtkWidget)

Returns the allocated width of `w` in pixels.

Related GTK function: [`gtk_widget_get_allocated_width`()]($(gtkdoc_method_url("gtk4","Widget","get_allocated_width")))
""" width

@doc """
    height(w::GtkWidget)

Returns the allocated height of `w` in pixels.

Related GTK function: [`gtk_widget_get_allocated_height`()]($(gtkdoc_method_url("gtk4","Widget","get_allocated_height")))
""" height

size(w::GtkWidget) = (width(w), height(w))

"""
    isvisible(w::GtkWidget) -> Bool

Returns whether `w` and all of its parents are marked as visible.

Related GTK function: [`gtk_widget_is_visible`()]($(gtkdoc_method_url("gtk4","Widget","is_visible")))
"""
isvisible(w::GtkWidget) = G_.is_visible(w)

"""
    visible(w::GtkWidget, state::Bool)

Control visibility of `w`. Note that `w` will not be visible unless its parent
is also visible.

Related GTK function: [`gtk_widget_set_visible`()]($(gtkdoc_method_url("gtk4","Widget","set_visible")))
"""
function visible(w::GtkWidget, state::Bool)
    G_.set_visible(w,state)
end

"""
    show(w::GtkWidget)

Flag `w` to be displayed and return `w`.

Related GTK function: [`gtk_widget_show`()]($(gtkdoc_method_url("gtk4","Widget","show")))
"""
function show(w::GtkWidget)
    G_.show(w)
    w
end

"""
    hide(w::GtkWidget)

Flag `w` to be hidden and return `w`. This is the opposite of `show`.

Related GTK function: [`gtk_widget_hide`()]($(gtkdoc_method_url("gtk4","Widget","hide")))
"""
function hide(w::GtkWidget)
    G_.hide(w)
    w
end

"""
    grab_focus(w::GtkWidget)

Gives `w` the keyboard focus for the window it is in. Returns `false` if this
fails.

Related GTK function: [`gtk_widget_grab_focus`()]($(gtkdoc_method_url("gtk4","Widget","grab_focus")))
"""
grab_focus(w::GtkWidget) = G_.grab_focus(w)

activate(w::GtkWidget) = G_.activate(w)

@doc """
    display(w::GtkWidget)

Gets the `GdkDisplay` for `w`. Should only be called if `w` has been added to
a widget hierarchy.

Related GTK function: [`gtk_widget_get_display`()]($(gtkdoc_method_url("gtk4","Widget","get_display")))
""" display

"""
    monitor(w::GtkWidget)

Gets the `GdkMonitor` where `w` is displayed, or `nothing` if the widget is not
part of a widget hierarchy.
"""
function monitor(w::GtkWidget)
    d = display(w)
    tl = toplevel(w)
    tl === nothing && return nothing
    s = G_.get_surface(GtkNative(tl))
    G_.get_monitor_at_surface(d,s)
end

"""
    cursor(w::GtkWidget, c)

Sets a cursor `c` when the mouse is over a widget `w`. If `c` is `nothing`, use
the default cursor for `w`.

Related GTK function: [`gtk_widget_set_cursor`()]($(gtkdoc_method_url("gtk4","Widget","set_cursor")))
"""
function cursor(w::GtkWidget, c::Union{Nothing,GdkCursor})
    G_.set_cursor(w, c)
end

function cursor(w::GtkWidget, n::AbstractString)
    G_.set_cursor_from_name(w, n)
end

@doc """
    cursor(w::GtkWidget)

Gets the cursor `c` for a widget `w`.

Related GTK function: [`gtk_widget_get_cursor`()]($(gtkdoc_method_url("gtk4","Widget","get_cursor")))
""" cursor

function iterate(w::GtkWidget, state=nothing)
    next = (state === nothing ? G_.get_first_child(w) : G_.get_next_sibling(state))
    next === nothing ? nothing : (next, next)
end

eltype(::Type{T}) where T <: GtkWidget = GtkWidget
IteratorSize(::Type{T}) where T <: GtkWidget = Base.SizeUnknown()

convert(::Type{GtkWidget}, w::AbstractString) = GtkLabel(w)

## GtkWidgetPaintable

GtkWidgetPaintable(w::GtkWidget) = G_.WidgetPaintable_new(w)

## GtkApplication

GtkApplication(id = nothing, flags = GLib.ApplicationFlags_NONE) = G_.Application_new(id,flags)
push!(app::GtkApplication, win::GtkWindow) = G_.add_window(app, win)
