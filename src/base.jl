destroy(w::GtkWidget) = G_.destroy(w)
parent(w::GtkWidget) = G_.get_parent(w)
hasparent(w::GtkWidget) = G_.get_parent(w) !== nothing
toplevel(w::GtkWidget) = G_.get_root(w)

### Functions and methods common to all GtkWidget objects
visible(w::GtkWidget) = G_.get_visible(w)
visible(w::GtkWidget, state::Bool) = G_.set_visible(w,state)

function show(w::GtkWidget)
    G_.show(w)
    w
end

hide(w::GtkWidget) = (G_.hide(w); w)
grab_focus(w::GtkWidget) = (G_.grab_focus(w); w)

function iterate(w::GtkWidget, state=nothing)
    next = (state === nothing ? G_.get_first_child(w) : G_.get_next_sibling(state))
    next === nothing ? nothing : (next, next)
end

convert(::Type{GtkWidget}, w::AbstractString) = GtkLabel(w)
