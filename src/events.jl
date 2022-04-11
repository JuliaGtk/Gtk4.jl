push!(w::GtkWidget, c::GtkEventController) = G_.add_controller(w,c)
widget(c::GtkEventController) = G_.get_widget(c)

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

function on_signal_destroy(@nospecialize(destroy_cb::Function), widget::GtkWidget, vargs...)
    signal_connect(destroy_cb, widget, "destroy", Nothing, (), vargs...)
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
