function GtkWindow(title::Union{Nothing, AbstractString} = nothing, w::Real = -1, h::Real = -1, resizable::Bool = true)
    win = G_.Window_new()
    if title !== nothing
        G_.set_title(win, title)
    end
    if resizable
        G_.set_default_size(win, w, h)
    else
        G_.set_resizable(win, false)
        G_.set_size_request(win, w, h)
    end
    show(win)
    win
end

function GtkWindow(widget::GtkWidget, args...)
    w=GtkWindow(args...)
    G_.set_child(w,widget)
    w
end

destroy(w::GtkWindow) = G_.destroy(w)

fullscreen(win::GtkWindow) = G_.fullscreen(win)
unfullscreen(win::GtkWindow) = G_.unfullscreen(win)

maximize(win::GtkWindow) = G_.maximize(win)
unmaximize(win::GtkWindow) = G_.unmaximize(win)

push!(w::GtkWindow, widget::GtkWidget) = G_.set_child(w, widget)
