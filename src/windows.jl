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
        (Ptr{GObject}, Cuint, Cint, Cint, Ptr{UInt8}),
        parent, flags, typ, ButtonsType_NONE, message); kwargs...)
    for (k, v) in buttons
        push!(w, k, v)
    end
    w
end

ask_dialog(message::AbstractString, parent = nothing) =
        ask_dialog(message, "No", "Yes", parent)

function ask_dialog(message::AbstractString, no_text, yes_text, parent = nothing)
    dlg = GtkMessageDialog(message, ((no_text, Integer(ResponseType_NO)), (yes_text, Integer(ResponseType_YES))),
            DialogFlags_DESTROY_WITH_PARENT, MessageType_QUESTION, parent)
end

function destroy_dialog(d::GtkDialog, response_id)
    destroy(d)
end

for (func, flag) in (
        (:info_dialog, :(MessageType_INFO)),
        (:warn_dialog, :(MessageType_WARNING)),
        (:error_dialog, :(MessageType_ERROR)))
    @eval function $func(message::AbstractString, parent = nothing)
        parent = (parent === nothing ? C_NULL : parent)
        w = GtkMessageDialogLeaf(ccall((:gtk_message_dialog_new, libgtk4), Ptr{GObject},
            (Ptr{GObject}, Cuint, Cint, Cint, Ptr{UInt8}),
            parent, DialogFlags_DESTROY_WITH_PARENT,
            $flag, ButtonsType_CLOSE, message))
        signal_connect(destroy_dialog,w,"response")
        w
    end
end

function input_dialog(message::AbstractString, entry_default::AbstractString, buttons = (("Cancel", 0), ("Accept", 1)), parent = nothing)
    parent = (parent === nothing ? C_NULL : parent)
    widget = GtkMessageDialog(message, buttons, DialogFlags_DESTROY_WITH_PARENT, MessageType_INFO, parent)
    box = content_area(widget)
    entry = GtkEntry(; text = entry_default)
    push!(box, entry)
    return widget
end

function content_area(widget::GtkDialog)
    boxp = G_.get_content_area(widget)
end

## FileChoosers

function GtkFileChooserDialog(title::AbstractString, parent::Union{Nothing,GtkWindow}, action, button_text_response; kwargs...)
    parent = (parent === nothing ? C_NULL : parent)
    w = GtkFileChooserDialog(ccall((:gtk_file_chooser_dialog_new, libgtk4), Ptr{GObject},
                (Ptr{UInt8}, Ptr{GObject}, Cint, Ptr{Nothing}),
                title, parent, action, C_NULL); kwargs...)
    for (k, v) in button_text_response
        push!(w, k, Integer(v))
    end
    return w
end

function GtkFileChooserNative(title::AbstractString, parent::Union{Nothing,GtkWindow}, action, accept::AbstractString, cancel::AbstractString; kwargs...)
    w = G_.FileChooserNative_new(title, parent, action, accept, cancel)
    return w
end

const SingleComma = r"(?<!,), (?!,)"
function GtkFileFilter(; name::Union{AbstractString, Nothing} = nothing, pattern::AbstractString = "", mimetype::AbstractString = "")
    filt = G_.FileFilter_new()
    if !isempty(pattern)
        name == nothing && (name = pattern)
        for p in split(pattern, SingleComma)
            p = replace(p, ", , " => ", ")   # escape sequence for , is , ,
            G_.add_pattern(filt,p)
        end
    elseif !isempty(mimetype)
        name == nothing && (name = mimetype)
        for m in split(mimetype, SingleComma)
            m = replace(m, ", , " => ", ")
            G_.add_mime_type(filt, m)
        end
    else
        G_.add_pixbuf_formats(filt)
    end
    G_.set_name(filt, name === nothing || isempty(name) ? nothing : name)
    return filt
end
GtkFileFilter(pattern::AbstractString; name::Union{AbstractString, Nothing} = nothing) = GtkFileFilter(; name = name, pattern = pattern)

GtkFileFilter(filter::GtkFileFilter) = filter

function makefilters!(dlgp::GtkFileChooser, filters::Union{AbstractVector, Tuple})
    for f in filters
        G_.add_filter(dlgp, GtkFileFilter(f))
    end
end

function file_chooser_get_selection(dlg::Union{GtkFileChooserDialog,GtkFileChooserNative}, response_id)
    dlgp = GtkFileChooser(dlg)
    multiple = get_gtk_property(dlg, :select_multiple, Bool)
    local selection
    if response_id == ResponseType_ACCEPT
        if multiple
            filename_list = G_.get_files(dlgp)
            selection = String[GLib.G_.get_path(GFile(f)) for f in GListModel(filename_list)]
        else
            gfile = G_.get_file(dlgp)
            selection = GLib.G_.get_path(GFile(gfile))
        end
    else
        if multiple
            selection = String[]
        else
            selection = ""
        end
    end
    destroy(dlg)
    selection
end

function open_dialog(title::AbstractString, parent = nothing, filters::Union{AbstractVector, Tuple} = String[]; kwargs...)
    parent = (parent === nothing ? C_NULL : parent)
    dlg = GtkFileChooserDialog(title, parent, FileChooserAction_OPEN,
                                (("_Cancel", ResponseType_CANCEL),
                                 ("_Open",   ResponseType_ACCEPT)); kwargs...)
    dlgp = GtkFileChooser(dlg)
    if !isempty(filters)
        makefilters!(dlgp, filters)
    end
    show(dlg)
    dlg
end

function save_dialog(title::AbstractString, parent = GtkNullContainer(), filters::Union{AbstractVector, Tuple} = String[]; kwargs...)
    dlg = GtkFileChooserDialog(title, parent, FileChooserAction_SAVE,
                                (("_Cancel", ResponseType_CANCEL),
                                 ("_Save",   ResponseType_ACCEPT)); kwargs...)
    dlgp = GtkFileChooser(dlg)
    if !isempty(filters)
        makefilters!(dlgp, filters)
    end
    show(dlg)
    dlg
end

## Native dialogs

show(d::GtkNativeDialog) = G_.show(d)
hide(d::GtkNativeDialog) = G_.hide(d)
destroy(d::GtkNativeDialog) = G_.destroy(d)

function open_dialog_native(title::AbstractString, parent = nothing, filters::Union{AbstractVector, Tuple} = String[])
    dlg = GtkFileChooserNative(title, parent, FileChooserAction_OPEN, "Open", "Cancel")
    dlgp = GtkFileChooser(dlg)
    if !isempty(filters)
        makefilters!(dlgp, filters)
    end
    show(dlg)
    dlg
end

function save_dialog_native(title::AbstractString, parent = nothing, filters::Union{AbstractVector, Tuple} = String[])
    dlg = GtkFileChooserNative(title, parent, FileChooserAction_SAVE,"Save","Cancel")
    dlgp = GtkFileChooser(dlg)
    if !isempty(filters)
        makefilters!(dlgp, filters)
    end
    show(dlg)
    dlg
end

function GtkColorChooserDialog(title::AbstractString, parent)
    return G_.ColorChooserDialog_new(title, parent)
end

function color_chooser_dialog_get_selection(dlg::GtkColorChooserDialog, response_id)
    dlgp = GtkColorChooser(dlg)
    if unsafe_trunc(UInt16,response_id) == ResponseType_OK
        selection = G_.get_rgba(dlgp)
    else
        selection = nothing
    end
    destroy(dlg)
    selection
end

function color_dialog(title::AbstractString, parent = nothing)
    dlg = GtkColorChooserDialog(title, parent)
    show(dlg)
    dlg
end
