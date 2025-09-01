using Gtk4.GLib, Gtk4, Gtk4.Graphene
import Gtk4.GLib: _GObjectClass
import Gtk4: _GtkWidgetClass

function widget_measure(widget::Ptr{GObject}, orientation::Cint, for_size::Cint, minimum::Ptr{Cint}, natural::Ptr{Cint}, minimum_baseline::Ptr{Cint}, natural_baseline::Ptr{Cint})
    unsafe_store!(minimum, Cint(100))
    unsafe_store!(natural, Cint(100))
    nothing
end

function widget_snapshot(widget_ptr::Ptr{GObject}, snapshot_ptr::Ptr{GObject})
    widget = convert(GtkWidget, widget_ptr)
    snapshot = convert(GtkSnapshot, snapshot_ptr)
    w,h = size(widget)
    R = min(w,h)/4
    cx = w/2
    cy = h/2+R/4
    b = Gtk4.GskPathBuilder()

    function draw_circle(b, center)
        Gtk4.G_.add_circle(b, center, 3R/4)
        Gtk4.build(b)
    end

    center = GraphenePoint(cx,cy-R)
    p = draw_circle(b, center)
    Gtk4.G_.append_fill(snapshot, p, 0, GdkRGBA(0.22,0.596,0.149))

    center = GraphenePoint(cx-R*sin(2pi/3),cy-R*cos(2pi/3))
    p = draw_circle(b, center)
    Gtk4.G_.append_fill(snapshot, p, 0, GdkRGBA(0.796,0.235,0.2))

    center = GraphenePoint(cx-R*sin(-2pi/3),cy-R*cos(-2pi/3))
    p = draw_circle(b, center)
    Gtk4.G_.append_fill(snapshot, p, 0, GdkRGBA(0.584,0.345,0.698))

    nothing
end

function object_class_init(class::Ptr{_GObjectClass}, user_data)
    widget_klass_ptr = Ptr{_GtkWidgetClass}(class)
    widget_klass = unsafe_load(widget_klass_ptr)
    widget_klass.snapshot = @cfunction(widget_snapshot, Cvoid, (Ptr{GObject}, Ptr{GObject}))
    widget_klass.measure = @cfunction(widget_measure, Cvoid, (Ptr{GObject}, Cint, Cint, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}))
    unsafe_store!(widget_klass_ptr, widget_klass)
    nothing
end

mutable struct MyWidget <: GtkWidget
    handle::Ptr{GObject}
end

function GLib.g_type(::Type{T}) where T <: MyWidget
    gt = GLib.g_type_from_name(:MyWidget)
    if gt > 0
        return gt
    else
        object_class_init_cfunc = @cfunction(object_class_init, Cvoid, (Ptr{_GObjectClass}, Ptr{Cvoid}))
        return GLib.register_subtype(GtkWidget, :MyWidget, object_class_init_cfunc)
    end
end

MyWidget() = GLib.gobject_new(MyWidget)

w = MyWidget()

win=GtkWindow("custom widget")
win[] = w
