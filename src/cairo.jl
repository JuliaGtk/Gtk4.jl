using Cairo_jll
using Cairo

function canvas_draw_backing_store(w, cr, width, height, user_data) # cr is a Cairo context
    user_data==C_NULL && return

    ccall((:cairo_set_source_surface, libcairo), Nothing,
        (Ptr{Nothing}, Ptr{Nothing}, Float64, Float64), cr, user_data, 0, 0)
    ccall((:cairo_paint, libcairo), Nothing, (Ptr{Nothing},), cr)
end

mutable struct GtkCanvas <: GtkDrawingArea # NOT an @GType
    handle::Ptr{GObject}
    #mouse::MouseHandler
    resize::Union{Function, Nothing}
    draw::Union{Function, Nothing}
    back::CairoSurface   # backing store
    backcc::CairoContext

    function GtkCanvas(w = -1, h = -1)
        da = G_.DrawingArea_new()
        G_.set_size_request(da, w, h)
        ids = Vector{Culong}(undef, 0)
        widget = new(da.handle, nothing, nothing)
        #widget = new(da, false, false, MouseHandler(ids), nothing, nothing)
        #widget.mouse.widget = widget

        function on_resize(da::GtkWidget, width, height)
            widget.back = CairoARGBSurface(width, height)

            draw_back = @cfunction(canvas_draw_backing_store, Nothing, (Ptr{GObject}, Ptr{Nothing}, Cint, Cint, Ptr{Nothing}))
            ccall((:gtk_drawing_area_set_draw_func, libgtk4), Nothing, (Ptr{GObject}, Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}), da.handle, draw_back, widget.back.ptr, C_NULL)

            draw(widget, false)
        end

        signal_connect(Base.inferencebarrier(on_resize), widget, "resize")

        #push!(ids, on_signal_button_press(mousedown_cb, widget, false, widget.mouse))
        #push!(ids, on_signal_button_release(mouseup_cb, widget, false, widget.mouse))
        #push!(ids, on_signal_motion(mousemove_cb, widget, 0, 0, false, widget.mouse))
        #push!(ids, on_signal_scroll(mousescroll_cb, widget, false, widget.mouse))
        return GLib.gobject_move_ref(widget, da)
    end
end
const GtkCanvasLeaf = GtkCanvas
macro GtkCanvas(args...)
    :( GtkCanvas($(map(esc, args)...)) )
end

function resize(config::Function, widget::GtkCanvas)
    widget.resize = config
    widget.resize(widget)
    draw(widget, false)
    nothing
end

function draw(redraw::Function, widget::GtkCanvas)
    widget.draw = redraw
    draw(widget, false)
    nothing
end

function draw(widget::GtkCanvas, immediate::Bool = true)
    if !isdefined(widget, :back)
        return
    end
    if isa(widget.draw, Function)
        widget.draw(widget)
    end
    G_.queue_draw(widget)
end

function getgc(c::GtkCanvas)
    if !isdefined(c,:back)
      error("GtkCanvas not yet initialized.")
    end
    return CairoContext(c.back)
end

function cairo_surface(c::GtkCanvas)
    if !isdefined(c,:back)
      error("GtkCanvas not yet initialized.")
    end
    return c.back
end
