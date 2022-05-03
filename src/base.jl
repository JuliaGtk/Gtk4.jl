parent(w::GtkWidget) = G_.get_parent(w)
hasparent(w::GtkWidget) = G_.get_parent(w) !== nothing
toplevel(w::GtkWidget) = G_.get_root(w)

width(w::GtkWidget) = G_.get_allocated_width(w)
height(w::GtkWidget) = G_.get_allocated_height(w)
size(w::GtkWidget) = (width(w), height(w))

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

eltype(::Type{GtkWidget}) = GtkWidget
IteratorSize(::Type{GtkWidget}) = Base.SizeUnknown()

convert(::Type{GtkWidget}, w::AbstractString) = GtkLabel(w)

GtkApplication(id = nothing, flags = GLib.Constants.ApplicationFlags_NONE) = G_.Application_new(id,flags)
push!(app::GtkApplication, win::GtkWindow) = G_.add_window(app, win)
menubar(app::GtkApplication, mb) = G_.set_menubar(app, mb)
