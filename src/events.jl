push!(w::GtkWidget, c::GtkEventController) = G_.add_controller(w,c)
widget(c::GtkEventController) = G_.get_widget(c)

GtkEventControllerMotion() = G_.EventControllerMotion_new()
GtkEventControllerScroll(flags) = G_.EventControllerScroll_new(flags)
GtkEventControllerKey() = G_.EventControllerKey_new()

GtkGestureClick() = G_.GestureClick_new()
function GtkGestureClick(button)
    g = GtkGestureClick()
    G_.set_button(g, button)
    g
end

GtkGestureDrag() = G_.GestureDrag_new()
GtkGestureZoom() = G_.GestureZoom_new()

function on_signal_destroy(@nospecialize(destroy_cb::Function), widget::GtkWidget, vargs...)
    signal_connect(destroy_cb, widget, "destroy", Nothing, (), vargs...)
end

reveal(w::GtkWidget) = G_.queue_draw(w)
