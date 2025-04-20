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
    Gtk4.G_.append_color(snapshot, GdkRGBA("red"), GrapheneRect(0,0,w/2,h/2))
    Gtk4.G_.append_color(snapshot, GdkRGBA("green"), GrapheneRect(w/2,0,w/2,h/2))
    Gtk4.G_.append_color(snapshot, GdkRGBA("yellow"), GrapheneRect(0,h/2,w/2,h/2))
    Gtk4.G_.append_color(snapshot, GdkRGBA("blue"), GrapheneRect(w/2,h/2,w/2,h/2))
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
