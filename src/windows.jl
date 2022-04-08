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
getindex(w::GtkScrolledWindow) = G_.get_child(w)

GtkHeaderBar() = G_.HeaderBar_new()


## GtkDialog

function push!(d::GtkDialog, s::AbstractString, response::Integer)
    G_.add_button(d, s, response)
    d
end

function response(widget::GtkDialog, response_id)
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
    parent = (parent === nothing ? C_NULL : parent)
    w = GtkMessageDialogLeaf(ccall((:gtk_message_dialog_new, libgtk4), Ptr{GObject},
        (Ptr{GObject}, Cint, Cint, Cint, Ptr{UInt8}),
        parent, flags, typ, Constants.ButtonsType_NONE, message); kwargs...)
    for (k, v) in buttons
        push!(w, k, v)
    end
    w
end

ask_dialog(message::AbstractString, parent = nothing) =
        ask_dialog(message, "No", "Yes", parent)

function ask_dialog(message::AbstractString, no_text, yes_text, parent = nothing)
    dlg = GtkMessageDialog(message, ((no_text, Integer(Constants.ResponseType_NO)), (yes_text, Integer(Constants.ResponseType_YES))),
            Constants.DialogFlags_DESTROY_WITH_PARENT, Constants.MessageType_QUESTION, parent)
end

function destroy_dialog(d::GtkDialog, response_id)
    destroy(d)
end

for (func, flag) in (
        (:info_dialog, :(Constants.MessageType_INFO)),
        (:warn_dialog, :(Constants.MessageType_WARNING)),
        (:error_dialog, :(Constants.MessageType_ERROR)))
    @eval function $func(message::AbstractString, parent = nothing)
        parent = (parent === nothing ? C_NULL : parent)
        w = GtkMessageDialogLeaf(ccall((:gtk_message_dialog_new, libgtk4), Ptr{GObject},
            (Ptr{GObject}, Cint, Cint, Cint, Ptr{UInt8}),
            parent, Constants.DialogFlags_DESTROY_WITH_PARENT,
            $flag, Constants.ButtonsType_CLOSE, message))
        signal_connect(destroy_dialog,w,"response")
        w
    end
end

function input_dialog(message::AbstractString, entry_default::AbstractString, buttons = (("Cancel", 0), ("Accept", 1)), parent = nothing)
    parent = (parent === nothing ? C_NULL : parent)
    widget = GtkMessageDialog(message, buttons, Constants.DialogFlags_DESTROY_WITH_PARENT, Constants.MessageType_INFO, parent)
    box = content_area(widget)
    entry = GtkEntry(; text = entry_default)
    push!(box, entry)
    return widget
end

function content_area(widget::GtkDialog)
    boxp = G_.get_content_area(widget)
end
