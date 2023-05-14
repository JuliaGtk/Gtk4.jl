# Note: Packages that depend on Gtk4 should do precompilation with PrecompileTools if possible.
# However, PrecompileTools does not run a package's __init__(), which is pretty essential
# for almost anything in Gtk4.jl to work, so we don't use it here.

function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    precompile(Tuple{typeof(__init__)})
    precompile(Tuple{typeof(Gtk4.GLib.GClosureMarshal), Ptr{Nothing}, Ptr{Gtk4.GLib.GValue}, UInt32, Ptr{Gtk4.GLib.GValue}, Ptr{Nothing}, Ptr{Nothing}})
    precompile(Tuple{typeof(Gtk4.GLib.uv_prepare), Ptr{Nothing}, Ptr{Int32}})
    precompile(Tuple{typeof(Gtk4.GLib.uv_check), Ptr{Nothing}})
    precompile(Tuple{typeof(Gtk4.GLib.uv_dispatch), Ptr{Nothing}, Ptr{Nothing}, Int64})
    precompile(Tuple{typeof(Gtk4.GLib.g_yield), UInt64})
    precompile(Tuple{typeof(Gtk4.GLib.__init__)})
    precompile(Tuple{typeof(Gtk4.Pango.__init__)})
    precompile(Tuple{typeof(Gtk4.GdkPixbufLib.__init__)})
    precompile(Tuple{Type{GtkWindow},String})
    precompile(Tuple{Type{GtkWindow},String,Int64,Int64})
    precompile(Tuple{Type{GtkCanvas}})
    precompile(Tuple{Type{setindex!},GtkWindow,GtkWidget})
    precompile(Tuple{Type{cursor},GtkWidget,String})
    precompile(Tuple{Type{GtkGestureClick}})
    precompile(Tuple{Type{getgc},GtkCanvas})
    precompile(Tuple{Type{height},GtkWidget})
    precompile(Tuple{Type{width},GtkWidget})
end
