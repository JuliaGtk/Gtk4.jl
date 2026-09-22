import Cairo: CairoSurface, CairoContext, CairoARGBSurface, set_source_surface, paint
import ..GLib: _GObjectClass

using Cairo_jll
using ..Pango.Cairo

function _canvas_draw_backing_store(w, cr, width, height, user_data) # cr is a Cairo context, user_data is a Cairo surface
    user_data==C_NULL && return
    
    ccall((:cairo_set_source_surface, libcairo), Nothing,
          (Ptr{Nothing}, Ptr{Nothing}, Float64, Float64), cr, user_data, 0, 0)
    ccall((:cairo_paint, libcairo), Nothing, (Ptr{Nothing},), cr)
end

function _init_canvas!(widget, w, h)
    widget.back = CairoARGBSurface(w, h)
    widget.backcc = CairoContext(widget.back)
end

function _canvas_on_resize(::Ptr, width, height, canvas)
    if isrealized(canvas)
        _init_canvas!(canvas, width, height)
        canvas.is_sized = true

        if isa(canvas.resize, Function)
            canvas.resize(canvas)
        end

        draw_back = @cfunction(_canvas_draw_backing_store, Nothing, (Ptr{GObject}, Ptr{Nothing}, Cint, Cint, Ptr{Nothing}))
        ccall((:gtk_drawing_area_set_draw_func, libgtk4), Nothing, (Ptr{GObject}, Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}), getfield(canvas,:handle), draw_back, canvas.back.ptr, C_NULL)

        draw(canvas)
    end
    nothing
end

"""
    GtkCanvas(w = -1, h = -1, init_back = false; kwargs...)

Create a `GtkCanvas` widget for drawing using Cairo (based on
`GtkDrawingArea`). Optional arguments `w` and `h` can be used to set the
minimum width and height of the drawing area in pixels. If `init_back` is set
to true, the canvas's image CairoSurface will be initialized immediately, which
is useful for precompilation.

Keyword arguments can be used to set properties of the `GtkDrawingArea` widget.
"""
mutable struct GtkCanvas <: GtkDrawingArea # NOT a GType
    handle::Ptr{GObject}
    is_sized::Bool
    resize::Union{Function, Nothing}
    draw::Union{Function, Nothing}
    back::CairoSurface   # backing store
    backcc::CairoContext

    function GtkCanvas(w = -1, h = -1, init_back = false; kwargs...)
        da = GtkDrawingArea(; kwargs...)
        if w > 0 && h > 0
            G_.set_content_height(da, h)
            G_.set_content_width(da, w)
        elseif init_back
            error("Width and height arguments must be provided to immediately initialize GtkCanvas.")
        end
        widget = new(getfield(da,:handle), false, nothing, nothing)
        if init_back
            _init_canvas!(widget, w, h)
        end

        widget = GLib.gobject_move_ref(widget, da)
        signal_connect(Base.inferencebarrier(_canvas_on_resize), widget, "resize", Nothing, (Cint, Cint), false, widget)

        return widget
    end
end
const GtkCanvasLeaf = GtkCanvas

"""
    resize(config::Function, widget::GtkCanvas)

Set a function `config` to be called whenever the `GtkCanvas`'s size is changed and
trigger a redraw. The `config` function should have a single argument, the `GtkCanvas`,
from which the `CairoSurface` can be retrieved using [`getgc`](@ref).
"""
function resize(config::Function, widget::GtkCanvas)
    widget.resize = config
    if G_.get_realized(widget) && widget.is_sized
        widget.resize(widget)
        draw(widget)
    end
    nothing
end

### CairoCanvas is experimental and unstable

mutable struct CairoCanvas <: GtkWidget
    handle::Ptr{GObject}
    content_size::Tuple{Int,Int}
    is_sized::Bool
    resize::Union{Function, Nothing}
    draw::Union{Function, Nothing}
    back::CairoSurface   # backing store
    backcc::CairoContext

    function CairoCanvas(handle::Ptr{GObject}, w::Integer = -1, h::Integer = -1, init_back::Bool = false)
        content_size = (0,0)
        if w > 0 && h > 0
            content_size = (w,h)
        elseif init_back
            error("Width and height arguments must be provided to immediately initialize CairoCanvas.")
        end
        widget = new(handle, content_size, false, nothing, nothing)
        if init_back
            _init_canvas!(widget, w, h)
        end

        return widget
    end
end

"""
    getgc(c::GtkCanvas)

Return the CairoContext of the `CairoSurface` backing store of a `GtkCanvas`.
"""
function getgc(c::Union{GtkCanvas,CairoCanvas})
    isdefined(c,:backcc) || error("GtkCanvas not yet initialized.")
    return c.backcc
end

CairoContext(cr::cairoContext) = CairoContext(Ptr{Nothing}(cr.handle))
Cairo.cairoContext(cr::CairoContext) = cairoContext(Ptr{cairoContext}(cr.ptr),false)

function widget_measure(widget_ptr::Ptr{GObject}, orientation::Cint, for_size::Cint, minimum::Ptr{Cint}, natural::Ptr{Cint}, minimum_baseline::Ptr{Cint}, natural_baseline::Ptr{Cint})
    canvas = convert(CairoCanvas, widget_ptr)
    s = if orientation == Orientation_HORIZONTAL
        canvas.content_size[1]
    else
        canvas.content_size[2]
    end
    unsafe_store!(minimum, s)
    unsafe_store!(natural, s)
    unsafe_store!(natural_baseline, Cint(-1))
    nothing
end

function widget_size_allocate(widget_ptr::Ptr{GObject}, width::Cint, height::Cint, baseline::Cint)
    canvas = convert(CairoCanvas, widget_ptr)
    _init_canvas!(canvas, width, height)
    canvas.is_sized = true

    if isa(canvas.resize, Function)
        canvas.resize(canvas)
    end
    draw(canvas)
    nothing
end

function widget_snapshot(widget_ptr::Ptr{GObject}, snapshot_ptr::Ptr{GObject})
    canvas = convert(CairoCanvas, widget_ptr)
    snapshot = convert(GtkSnapshot, snapshot_ptr)
    w,h = size(canvas)
    cr = Gtk4.G_.append_cairo(snapshot, Ref(_GrapheneRect(0,0,w,h)))
    cc = CairoContext(Ptr{Nothing}(cr.handle))
    set_source_surface(cc, canvas.back)
    paint(cc)
    nothing
end

function object_class_init(class::Ptr{_GObjectClass}, user_data)
    widget_klass_ptr = Ptr{_GtkWidgetClass}(class)
    widget_klass = unsafe_load(widget_klass_ptr)
    widget_klass.snapshot = @cfunction(widget_snapshot, Cvoid, (Ptr{GObject}, Ptr{GObject}))
    widget_klass.measure = @cfunction(widget_measure, Cvoid, (Ptr{GObject}, Cint, Cint, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}))
    widget_klass.size_allocate = @cfunction(widget_size_allocate, Cvoid, (Ptr{GObject}, Cint, Cint, Cint))
    unsafe_store!(widget_klass_ptr, widget_klass)
    nothing
end

function GLib.g_type(::Type{T}) where T <: CairoCanvas
    gt = GLib.g_type_from_name(:CairoCanvas)
    if gt > 0
        return gt
    else
        object_class_init_cfunc = @cfunction(object_class_init, Cvoid, (Ptr{_GObjectClass}, Ptr{Cvoid}))
        return GLib.register_subtype(GtkWidget, :CairoCanvas, object_class_init_cfunc)
    end
end

function CairoCanvas(w::Integer = -1, h::Integer = -1, init_back::Bool = false; kwargs...)
    widget = GLib.gobject_new(CairoCanvas, w, h, init_back)
    GLib.setproperties!(widget; kwargs...)
    widget
end

"""
    cairo_surface(c::GtkCanvas)

Return the image `CairoSurface` backing store for a `GtkCanvas`.
"""
function cairo_surface(c::Union{GtkCanvas,CairoCanvas})
    isdefined(c,:back) || error("Canvas not yet initialized.")
    return c.back
end

"""
    draw(redraw::Function, widget::GtkCanvas)

Set a function `redraw` to be called whenever the `GtkCanvas`'s `CairoSurface`
needs to be redrawn. The function should have a single argument, the
`GtkCanvas`, from which the `CairoSurface` can be retrieved using
[`getgc`](@ref).
"""
function draw(redraw::Function, widget::Union{GtkCanvas,CairoCanvas})
    widget.draw = redraw
    draw(widget)
    nothing
end

"""
    draw(widget::GtkCanvas)

Triggers a redraw of the canvas using a previously set `redraw` function.
"""
function draw(widget::Union{GtkCanvas,CairoCanvas})
    if !isdefined(widget, :back)
        #@warn("backing store not defined")
        return
    end
    if isa(widget.draw, Function)
        widget.draw(widget)
    end
    G_.queue_draw(widget)
end

