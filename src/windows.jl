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
titlebar(win::GtkWindow, w::GtkWidget) = G_.set_titlebar(win, w)

push!(w::GtkWindow, widget::GtkWidget) = G_.set_child(w, widget)
setindex!(w::GtkWindow, widget::GtkWidget) = G_.set_child(w, widget)

GtkApplicationWindow(app::GtkApplication) = G_.ApplicationWindow_new(app)
function GtkApplicationWindow(app::GtkApplication, title::AbstractString)
    win = GtkApplicationWindow(app)
    G_.set_title(win, title)
    win
end

GtkScrolledWindow() = G_.ScrolledWindow_new()
setindex!(w::GtkScrolledWindow, widg::GtkWidget) = G_.set_child(w,widg)
getindex(w::GtkScrolledWindow) = G_.get_child(w,widg)

GtkHeaderBar() = G_.HeaderBar_new()


## GtkDialog

function push!(d::GtkDialog, s::AbstractString, response::Integer)
    G_.add_button(d, s, response)
    d
end

function response(widget::GtkDialog, response_id::Integer)
    G_.response(widget, response_id)
end

function GtkDialog(title::AbstractString, parent::GtkWindow, flags::Integer, buttons; kwargs...)
    w = GtkDialogLeaf(ccall((:gtk_dialog_new_with_buttons, libgtk), Ptr{GObject},
                (Ptr{UInt8}, Ptr{GObject}, Cint, Ptr{Nothing}),
                title, parent, flags, C_NULL); kwargs...)
    for (k, v) in buttons
        push!(w, k, v)
    end
    w
end

GtkAboutDialogLeaf() = G_.AboutDialog_new()

function GtkMessageDialog(message::AbstractString, buttons, flags, typ, parent = nothing; kwargs...)
    if parent === nothing
        parent = C_NULL
    end
    w = GtkMessageDialogLeaf(ccall((:gtk_message_dialog_new, libgtk4), Ptr{GObject},
        (Ptr{GObject}, Cint, Cint, Cint, Ptr{UInt8}),
        parent, flags, typ, Constants.ButtonsType_NONE, C_NULL); kwargs...)
    set_gtk_property!(w, :text, message)
    for (k, v) in buttons
        push!(w, k, v)
    end
    w
end

ask_dialog(message::AbstractString, parent = nothing) =
        ask_dialog(message, "No", "Yes", parent)

function ask_dialog(message::AbstractString, no_text, yes_text, parent = nothing)
    dlg = GtkMessageDialog(message, ((no_text, 0), (yes_text, 1)),
            Constants.DialogFlags_DESTROY_WITH_PARENT, Constants.MessageType_QUESTION, parent)
end

for (func, flag) in (
        (:info_dialog, :(GtkMessageType.INFO)),
        (:warn_dialog, :(GtkMessageType.WARNING)),
        (:error_dialog, :(GtkMessageType.ERROR)))
    @eval function $func(message::AbstractString, parent = GtkNullContainer())
        w = GtkMessageDialogLeaf(ccall((:gtk_message_dialog_new, libgtk), Ptr{GObject},
            (Ptr{GObject}, Cint, Cint, Cint, Ptr{UInt8}),
            parent, GtkDialogFlags.DESTROY_WITH_PARENT,
            $flag, GtkButtonsType.CLOSE, C_NULL))
        set_gtk_property!(w, :text, message)
    end
end

function input_dialog(message::AbstractString, entry_default::AbstractString, buttons = (("Cancel", 0), ("Accept", 1)), parent = GtkNullContainer())
    widget = GtkMessageDialog(message, buttons, GtkDialogFlags.DESTROY_WITH_PARENT, GtkMessageType.INFO, parent)
    box = content_area(widget)
    entry = GtkEntry(; text = entry_default)
    push!(box, entry)
    return widget
end

function content_area(widget::GtkDialog)
    boxp = G_.get_content_area(widget)
end
