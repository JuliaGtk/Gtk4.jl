# Note: Packages that depend on Gtk4 should do precompilation with PrecompileTools if possible.
# However, PrecompileTools does not run a package's __init__(), which is pretty essential
# for almost anything in Gtk4.jl to work, so we don't use it here.

function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    precompile(Tuple{typeof(__init__)})
    precompile(Tuple{typeof(GLib.GClosureMarshal), Ptr{Nothing}, Ptr{GLib.GValue}, UInt32, Ptr{GLib.GValue}, Ptr{Nothing}, Ptr{Nothing}})
    precompile(Tuple{typeof(GLib.uv_prepare), Ptr{Nothing}, Ptr{Int32}})
    precompile(Tuple{typeof(GLib.uv_check), Ptr{Nothing}})
    precompile(Tuple{typeof(GLib.uv_dispatch), Ptr{Nothing}, Ptr{Nothing}, Int64})
    precompile(Tuple{typeof(GLib.g_yield), UInt64})
    precompile(Tuple{typeof(GLib.__init__)})
    precompile(Tuple{typeof(Pango.__init__)})
    precompile(Tuple{typeof(GdkPixbufLib.__init__)})
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
