using Gtk4.GLib, Gtk4
import Gtk4.GLib: _GObjectClass
import Gtk4: _GtkWidgetClass
import Gtk4.Graphene: _GrapheneRect

function widget_measure(widget::Ptr{GObject}, orientation::Cint, for_size::Cint, minimum::Ptr{Cint}, natural::Ptr{Cint}, minimum_baseline::Ptr{Cint}, natural_baseline::Ptr{Cint})
    unsafe_store!(minimum, Cint(100))
    unsafe_store!(natural, Cint(100))
    nothing
end

function widget_snapshot(widget_ptr::Ptr{GObject}, snapshot_ptr::Ptr{GObject})
    widget = convert(GtkWidget, widget_ptr)
    snapshot = convert(GtkSnapshot, snapshot_ptr)
    w,h = size(widget)
    Gtk4.G_.append_color(snapshot, GdkRGBA("red"), Ref(_GrapheneRect(0,0,w/2,h/2)))
    Gtk4.G_.append_color(snapshot, GdkRGBA("green"), Ref(_GrapheneRect(w/2,0,w/2,h/2)))
    Gtk4.G_.append_color(snapshot, GdkRGBA("yellow"), Ref(_GrapheneRect(0,h/2,w/2,h/2)))
    Gtk4.G_.append_color(snapshot, GdkRGBA("blue"), Ref(_GrapheneRect(w/2,h/2,w/2,h/2)))
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
        base_gtype = GLib.g_type(GtkWidget)
        tq=GLib.G_.type_query(base_gtype)
        typeinfo = _GTypeInfo(tq.class_size,
                        C_NULL,   # base_init
                        C_NULL,   # base_finalize
                        @cfunction(object_class_init, Cvoid, (Ptr{_GObjectClass}, Ptr{Cvoid})),
                        C_NULL,   # class_finalize
                        C_NULL,   # class_data
                        tq.instance_size,
                        0,        # n_preallocs
                        C_NULL,   # instance_init
                        C_NULL)   # value_table
        return GLib.G_.type_register_static(base_gtype,:MyWidget,Ref(typeinfo),GLib.TypeFlags_FINAL)
    end
end

function MyWidget()
    gtype = GLib.g_type(MyWidget)
    h = ccall(("g_object_new", GLib.libgobject), Ptr{GObject}, (UInt64, Ptr{Cvoid}), gtype, C_NULL)
    MyWidget(h)
end

w = MyWidget()

win=GtkWindow("custom widget")
win[] = w
