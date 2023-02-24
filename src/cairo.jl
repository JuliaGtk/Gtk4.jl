import Cairo: CairoSurface, CairoContext, CairoARGBSurface

using Cairo_jll

function canvas_draw_backing_store(w, cr, width, height, user_data) # cr is a Cairo context, user_data is a Cairo surface
    user_data==C_NULL && return

    ccall((:cairo_set_source_surface, libcairo), Nothing,
        (Ptr{Nothing}, Ptr{Nothing}, Float64, Float64), cr, user_data, 0, 0)
    ccall((:cairo_paint, libcairo), Nothing, (Ptr{Nothing},), cr)
end

mutable struct GtkCanvas <: GtkDrawingArea # NOT a GType
    handle::Ptr{GObject}
    is_sized::Bool
    resize::Union{Function, Nothing}
    draw::Union{Function, Nothing}
    back::CairoSurface   # backing store
    backcc::CairoContext

    function GtkCanvas(w = -1, h = -1)
        da = G_.DrawingArea_new()
        G_.set_size_request(da, w, h)
        widget = new(da.handle, false, nothing, nothing)

        function on_realize(da::GtkWidget)
            if widget.is_sized
                on_resize(da,1,1)
            end
            nothing
        end

        on_resize(da::GtkDrawingArea, width, height) = on_resize(da, Cint(width), Cint(height))
        function on_resize(da::GtkDrawingArea, width::Cint, height::Cint)
            widget.is_sized = true
            if G_.get_realized(widget)
                widget.back = CairoARGBSurface(width, height)
                widget.backcc = CairoContext(widget.back)

                if isa(widget.resize, Function)
                    widget.resize(widget)
                end

                draw_back = @cfunction(canvas_draw_backing_store, Nothing, (Ptr{GObject}, Ptr{Nothing}, Cint, Cint, Ptr{Nothing}))
                ccall((:gtk_drawing_area_set_draw_func, libgtk4), Nothing, (Ptr{GObject}, Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}), da.handle, draw_back, widget.back.ptr, C_NULL)

                draw(widget)
            end
            nothing
        end

        signal_connect(Base.inferencebarrier(on_realize), widget, "realize")
        signal_connect(Base.inferencebarrier(on_resize), widget, "resize")

        return GLib.gobject_move_ref(widget, da)
    end
end
const GtkCanvasLeaf = GtkCanvas

function resize(config::Function, widget::GtkCanvas)
    widget.resize = config
    if G_.get_realized(widget) && widget.is_sized
        widget.resize(widget)
        draw(widget)
    end
    nothing
end

function draw(redraw::Function, widget::GtkCanvas)
    widget.draw = redraw
    draw(widget)
    nothing
end

function draw(widget::GtkCanvas)
    if !isdefined(widget, :back)
        #@warn("backing store not defined")
        return
    end
    if isa(widget.draw, Function)
        widget.draw(widget)
    end
    G_.queue_draw(widget)
end

function getgc(c::GtkCanvas)
    if !isdefined(c,:backcc)
      error("GtkCanvas not yet initialized.")
    end
    return c.backcc
end

function cairo_surface(c::GtkCanvas)
    if !isdefined(c,:back)
      error("GtkCanvas not yet initialized.")
    end
    return c.back
end
