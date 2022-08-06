push!(w::GtkWidget, c::GtkEventController) = G_.add_controller(w,c)

"""
    widget(c::GtkEventController)

Returns the widget associated with an event controller.
"""
widget(c::GtkEventController) = G_.get_widget(c)

"""
    find_controller(w::GtkWidget, ::Type{T}) where T <: GtkEventController

Returns an event controller of type T connected to a widget, or nothing if one
doesn't exist. This function is intended for testing purposes (to simulate
events) and is not recommended otherwise, as there is a performance
penalty for creating a list of a widget's event controllers.

Related GTK function: [`gtk_widget_observe_controllers`](https://docs.gtk.org/gtk4/method.Widget.observe_controllers.html))
"""
function find_controller(w::GtkWidget, ::Type{T}) where T<: GtkEventController
    list = GListModel(G_.observe_controllers(w))
    i=findfirst(c->isa(c,T), list)
    i!==nothing ? list[i] : nothing
end

function GtkEventControllerMotion(widget=nothing)
    g = G_.EventControllerMotion_new()
    widget !== nothing && push!(widget, g)
    g
end
function GtkEventControllerScroll(flags,widget=nothing)
    g = G_.EventControllerScroll_new(flags)
    widget !== nothing && push!(widget, g)
    g
end
function GtkEventControllerKey(widget=nothing)
    g = G_.EventControllerKey_new()
    widget !== nothing && push!(widget, g)
    g
end

function GtkGestureClick(widget=nothing,button=0)
    g = G_.GestureClick_new()
    button != 0 && G_.set_button(g, button)
    widget !== nothing && push!(widget, g)
    g
end

function GtkGestureDrag(widget=nothing)
    g = G_.GestureDrag_new()
    widget !== nothing && push!(widget, g)
    g
end

function GtkGestureZoom(widget=nothing)
    g = G_.GestureZoom_new()
    widget !== nothing && push!(widget, g)
    g
end

function GtkEventControllerFocus(widget=nothing)
    g = G_.EventControllerFocus_new()
    widget !== nothing && push!(widget, g)
    g
end

function on_signal_destroy(@nospecialize(destroy_cb::Function), widget::GtkWidget, vargs...)
    signal_connect(destroy_cb, widget, "destroy", Cvoid, (), vargs...)
end

function on_signal_button_press(@nospecialize(press_cb::Function), widget::GtkWidget, vargs...)
    g = GtkGestureClick(widget)
    signal_connect(press_cb, g, "pressed", Cvoid, (Cint, Cdouble, Cdouble), vargs...)
end

function on_signal_button_release(@nospecialize(release_cb::Function), widget::GtkWidget, vargs...)
    g = GtkGestureClick(widget)
    signal_connect(release_cb, widget, "released", Cvoid, (Cint, Cdouble, Cdouble), vargs...)
end


reveal(w::GtkWidget) = G_.queue_draw(w)
