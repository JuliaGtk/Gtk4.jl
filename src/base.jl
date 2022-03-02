parent(w::GtkWidget) = G_.get_parent(w)
hasparent(w::GtkWidget) = G_.get_parent(w) !== nothing

### Functions and methods common to all GtkWidget objects
visible(w::GtkWidget) = G_.get_visible(w)
visible(w::GtkWidget, state::Bool) = G_.set_visible(w,state)

function show(w::GtkWidget)
    G_.show(w)
    w
end

hide(w::GtkWidget) = (G_.hide(w); w)
grab_focus(w::GtkWidget) = (G_.grab_focus(w); w)

# function pushfirst!(w::GtkWidget, child::GtkWidget)
#     G_.insert_after(child, w, nothing)
#     w
# end
#
# function push!(w::GtkWidget, child::GtkWidget)
#     G_.insert_before(child, w, nothing)
#     w
# end
