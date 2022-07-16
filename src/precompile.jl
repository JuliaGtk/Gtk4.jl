function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    precompile(Tuple{typeof(__init__)})
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
