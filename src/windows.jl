function GtkWindow(title::Union{Nothing, AbstractString}, w::Real = -1, h::Real = -1, resizable::Bool = true, show_window::Bool = true)
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
    show_window && show(win)
    win
end

function GtkWindow(widget::GtkWidget, args...)
    w=GtkWindow(args...)
    G_.set_child(w,widget)
    if isempty(args) # to avoid breaking too much code downstream, show by default
        show(w)
    end
    w
end

default_size(win::GtkWindow, w, h) = G_.set_default_size(win, w, h)

"""
    destroy(win::GtkWindow)

Drop GTK's reference to `win`.

Related GTK function: [`gtk_window_destroy`()]($(gtkdoc_method_url("gtk4","Window","destroy")))
"""
function destroy(w::GtkWindow)
    G_.destroy(w)
end

"""
    close(win::GtkWindow)

Request that `win` is closed.

Related GTK function: [`gtk_window_close`()]($(gtkdoc_method_url("gtk4","Window","close")))
"""
close(w::GtkWindow) = G_.close(w)

"""
    fullscreen(win::GtkWindow)

Set `win` to fullscreen mode.

See also [`unfullscreen`](@ref).

Related GTK function: [`gtk_window_fullscreen`()]($(gtkdoc_method_url("gtk4","Window","fullscreen")))
"""
fullscreen(win::GtkWindow) = G_.fullscreen(win)

"""
    unfullscreen(win::GtkWindow)

If `win` is in fullscreen mode, return it to normal mode.

See also [`fullscreen`](@ref).

Related GTK function: [`gtk_window_unfullscreen`()]($(gtkdoc_method_url("gtk4","Window","unfullscreen")))
"""
unfullscreen(win::GtkWindow) = G_.unfullscreen(win)

"""
    maximize(win::GtkWindow)

Request that the window `win` be maximized.

See also [`unmaximize`](@ref).

Related GTK function: [`gtk_window_maximize`()]($(gtkdoc_method_url("gtk4","Window","maximize")))
"""
maximize(win::GtkWindow) = G_.maximize(win)

"""
    unmaximize(win::GtkWindow)

If `win` is maximized, return it to its former size.

See also [`maximize`](@ref).

Related GTK function: [`gtk_window_unmaximize`()]($(gtkdoc_method_url("gtk4","Window","unmaximize")))
"""
unmaximize(win::GtkWindow) = G_.unmaximize(win)

"""
    present(win::GtkWindow)
    present(win::GtkWindow, timestamp)

Presents a window to the user. Usually means move it to the front. According to the GTK docs, this
function "should not be used" without including a timestamp for the user's request.

Related GTK function: [`gtk_window_present`()]($(gtkdoc_method_url("gtk4","Window","present")))
Related GTK function: [`gtk_window_present_with_time`()]($(gtkdoc_method_url("gtk4","Window","present_with_time")))
"""
present(win::GtkWindow) = G_.present(win)
present(win::GtkWindow, timestamp) = G_.present_with_time(win, timestamp)

push!(w::GtkWindow, widget::GtkWidget) = (G_.set_child(w, widget); w)
setindex!(w::GtkWindow, widget::Union{Nothing,GtkWidget}) = G_.set_child(w, widget)
getindex(w::GtkWindow) = G_.get_child(w)

function push!(wg::GtkWindowGroup, w::GtkWindow)
    G_.add_window(wg,w)
    wg
end
function delete!(wg::GtkWindowGroup, w::GtkWindow)
    G_.remove_window(wg,w)
    wg
end

function GtkApplicationWindow(app::GtkApplication, title::AbstractString)
    win = GtkApplicationWindow(app)
    G_.set_title(win, title)
    win
end

setindex!(w::GtkScrolledWindow, widg::Union{Nothing,GtkWidget}) = G_.set_child(w,widg)
getindex(w::GtkScrolledWindow) = G_.get_child(w)

## GtkHeaderBar

push!(hb::GtkHeaderBar, w::GtkWidget) = (G_.pack_end(hb, w); hb)
pushfirst!(hb::GtkHeaderBar, w::GtkWidget) = (G_.pack_start(hb, w); hb)
delete!(hb::GtkHeaderBar, w::GtkWidget) = (G_.remove(hb, w); hb)

## GtkDialog

function push!(d::GtkDialog, s::AbstractString, response)
    G_.add_button(d, s, Int32(response))
    d
end

function response(widget::GtkDialog, response_id)
    G_.response(widget, Int32(response_id))
end

function GtkDialog(title::AbstractString, buttons, flags, parent = nothing; kwargs...)
    parent = (parent === nothing ? C_NULL : parent)
    w = GtkDialogLeaf(ccall((:gtk_dialog_new_with_buttons, libgtk4), Ptr{GObject},
                (Ptr{UInt8}, Ptr{GObject}, Cint, Ptr{Nothing}),
                title, parent, flags, C_NULL); kwargs...)
    for (k, v) in buttons
        push!(w, k, v)
    end
    w
end

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

"""
    ask_dialog(question::AbstractString, parent = nothing; timeout = -1)

Create a dialog with a message `question` and two buttons "No" and "Yes". Returns `true` if
"Yes" is selected and `false` if "No" is selected or the dialog (or its parent window
`parent`) is closed. The optional input `timeout` (disabled by default) can be used to set
a time in seconds after which the dialog will close and `false` will be returned.
"""
ask_dialog(question::AbstractString, parent = nothing; timeout = -1) =
        ask_dialog(question, "No", "Yes", parent; timeout = timeout)

function ask_dialog(message::AbstractString, no_text, yes_text, parent = nothing; timeout = -1)
    res = Ref{Bool}(false)
    c = Condition()

    ask_dialog(message, no_text, yes_text, parent; timeout) do res_
        res[] = res_
        notify(c)
    end
    wait(c)
    return res[]
end

function ask_dialog(callback::Function, message::AbstractString, no_text, yes_text, parent = nothing; timeout = -1)
    dlg = GtkMessageDialog(message, ((no_text, ResponseType_NO), (yes_text, ResponseType_YES)),
            DialogFlags_DESTROY_WITH_PARENT, MessageType_QUESTION, parent)

    function on_response(dlg, response_id)
        callback(response_id == Int32(ResponseType_YES))
        destroy(dlg)
    end

    signal_connect(on_response, dlg, "response")
    show(dlg)

    if timeout > 0
        emit(timer) = response(dlg, Gtk4.ResponseType_NO)
        Timer(emit, timeout)
    end
    return dlg
end

"""
    info_dialog(message::AbstractString, parent = nothing; timeout = -1)

Create a dialog with an informational message `message`. Returns when the dialog (or its
parent window `parent`) is closed. The optional input `timeout` (disabled by default) can be
used to set a time in seconds after which the dialog will close and `false` will be
returned.
""" info_dialog

for (func, flag) in (
        (:info_dialog, :(MessageType_INFO)),
        (:warn_dialog, :(MessageType_WARNING)),
        (:error_dialog, :(MessageType_ERROR)))
    @eval function $func(message::AbstractString, parent = nothing; timeout = -1)
        res = Ref{String}("")
        c = Condition()

        $func(message, parent; timeout) do
            notify(c)
        end
        wait(c)
        return
    end

    @eval function $func(callback::Function, message::AbstractString, parent = nothing; timeout = -1)
        dlg = GtkMessageDialog(message, (("Close",0),), DialogFlags_DESTROY_WITH_PARENT, $flag, parent)

        function destroy_dialog(dlg, response_id)
            callback()
            destroy(dlg)
        end

        signal_connect(destroy_dialog, dlg, "response")
        show(dlg)

        if timeout > 0
            emit(timer) = response(dlg, Gtk4.ResponseType_CANCEL)
            Timer(emit, timeout)
        end

        return dlg
    end
end

"""
    input_dialog(message::AbstractString, entry_default::AbstractString, buttons = (("Cancel", 0), ("Accept", 1)), parent = nothing; timeout = -1)

Create a dialog with a message `message` and a text entry. Returns the string in the entry
when the "Accept" button is pressed, or `entry_default` if "Cancel" is pressed or the dialog
or its parent window `parent` is closed. The optional input `timeout` (disabled by default)
can be used to set a time in seconds after which the dialog will close and `entry_default`
will be returned.
"""
function input_dialog(message::AbstractString, entry_default::AbstractString, buttons = (("Cancel", 0), ("Accept", 1)), parent = nothing; timeout = -1)
    res = Ref{String}("")
    c = Condition()

    input_dialog(message, entry_default, buttons, parent; timeout) do res_
        res[] = res_
        notify(c)
    end
    wait(c)
    return res[]
end

function input_dialog(callback::Function, message::AbstractString, entry_default::AbstractString,
                      buttons = (("Cancel", 0), ("Accept", 1)), parent = nothing; timeout = -1)
    dlg = GtkMessageDialog(message, buttons, DialogFlags_DESTROY_WITH_PARENT, MessageType_INFO, parent)
    box = content_area(dlg)
    entry = GtkEntry()
    entry.text = entry_default
    push!(box, entry)

    function on_response(dlg, response_id)
        if response_id == 1
            res = text(GtkEditable(entry))
        else
            res = ""
        end
        callback(res)
        destroy(dlg)
    end

    signal_connect(on_response, dlg, "response")
    show(dlg)

    if timeout > 0
        emit(timer) = response(dlg, 0)
        Timer(emit, timeout)
    end
    return dlg
end

## FileChoosers

function GtkFileChooserDialog(title::AbstractString, parent::Union{Nothing,GtkWindow}, action, button_text_response; kwargs...)
    parent = (parent === nothing ? C_NULL : parent)
    d = ccall((:gtk_file_chooser_dialog_new, libgtk4), Ptr{GObject},
                (Ptr{UInt8}, Ptr{GObject}, Cint, Ptr{Nothing}),
                                   title, parent, action, C_NULL)
    w = convert(GtkFileChooserDialog, d)
    # apply properties
    for (k, v) in button_text_response
        push!(w, k, Integer(v))
    end
    return w
end

const SingleComma = r"(?<!,), (?!,)"
function GtkFileFilter(pattern::AbstractString, mimetype::AbstractString = ""; kwargs...)
    filt = G_.FileFilter_new()
    if !isempty(pattern)
        filt.name = pattern
        for p in split(pattern, SingleComma)
            p = replace(p, ", , " => ", ")   # escape sequence for , is , ,
            G_.add_pattern(filt,p)
        end
    elseif !isempty(mimetype)
        filt.name = mimetype
        for m in split(mimetype, SingleComma)
            m = replace(m, ", , " => ", ")
            G_.add_mime_type(filt, m)
        end
    else
        G_.add_pixbuf_formats(filt)
    end
    GLib.setproperties!(filt; kwargs...)
    return filt
end

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
    return selection
end

## Native file dialogs

show(d::GtkNativeDialog) = G_.show(d)
hide(d::GtkNativeDialog) = G_.hide(d)
destroy(d::GtkNativeDialog) = G_.destroy(d)

"""
    open_dialog(title::AbstractString, parent = nothing, filters::Union{AbstractVector, Tuple} = String[]; timeout = -1, multiple = false, start_folder = "")

Create a dialog for choosing a file or folder to be opened. Returns the path chosen by the user, or "" if "Cancel" is pressed or the dialog or its parent window `parent` is closed. The dialog title is set using `title`. The argument `filters` can be used to show only directory contents that match certain file extensions.

Keyword arguments:
`timeout`: The optional input `timeout` (disabled by default) can be used to set a time in seconds after which the dialog will close and "" will be returned.
`multiple`: if `true`, multiple files can be selected, and a list of file paths is returned rather than a single path.
`start_folder`: if set, the dialog will start out browsing a particular folder. Otherwise GTK will decide.
"""
function open_dialog(title::AbstractString, parent = nothing, filters::Union{AbstractVector, Tuple} = String[]; timeout = -1, multiple = false, select_folder = false, start_folder = "")
    res = Ref{String}("")
    c = Condition()

    open_dialog(title, parent, filters; timeout, multiple, select_folder, start_folder) do filename
        res[] = filename
        notify(c)
    end
    wait(c)
    return res[]
end

function open_dialog(callback::Function, title::AbstractString, parent = nothing,
                    filters::Union{AbstractVector, Tuple} = String[]; timeout = -1, multiple = false, select_folder = false, start_folder = "")
    action = select_folder ? FileChooserAction_SELECT_FOLDER : FileChooserAction_OPEN
    dlg = GtkFileChooserNative(title, parent, action, "Open", "Cancel")
    dlgp = GtkFileChooser(dlg)
    if !isempty(filters)
        makefilters!(dlgp, filters)
    end
    if start_folder != ""
        curr = Gtk4.GLib.G_.file_new_for_path(start_folder)
        Gtk4.G_.set_current_folder(dlgp, GFile(curr))
    end

    function on_response(dlg, response_id)
        if ResponseType(unsafe_trunc(UInt16, response_id)) == ResponseType_ACCEPT
            file = G_.get_file(dlgp)
            sel = GLib.G_.get_path(GFile(file))
        else
            sel = ""
        end
        callback(sel)
        destroy(dlg)
    end

    signal_connect(on_response, dlg, "response")
    show(dlg)

    if timeout > 0
        emit(timer) = on_response(dlg, Int32(Gtk4.ResponseType_CANCEL))
        Timer(emit, timeout)
    end
    return dlg
end

"""
    save_dialog(title::AbstractString, parent = nothing, filters::Union{AbstractVector, Tuple} = String[]; timeout = -1, start_folder = "")

Create a dialog for choosing a file to be saved to. Returns the path chosen by the user, or "" if "Cancel" is pressed or the dialog or its parent window `parent` is closed. The window title is set using `title`. The argument `filters` can be used to show only directory contents that match certain file extensions.

Keyword arguments:
`timeout`: The optional input `timeout` (disabled by default) can be used to set a time in seconds after which the dialog will close and "" will be returned.
`start_folder`: if set, the dialog will start out browsing a particular folder. Otherwise GTK will decide.
"""
function save_dialog(title::AbstractString, parent = nothing, filters::Union{AbstractVector, Tuple} = String[]; timeout = -1, start_folder = "")
    res = Ref{String}("")
    c = Condition()

    save_dialog(title, parent, filters; timeout, start_folder) do filename
        res[] = filename
        notify(c)
    end
    wait(c)
    return res[]
end

function save_dialog(callback::Function, title::AbstractString, parent = nothing, filters::Union{AbstractVector, Tuple} = String[]; start_folder = "", timeout=-1)
  dlg = GtkFileChooserNative(title, parent, FileChooserAction_SAVE, "Save", "Cancel")
  dlgp = GtkFileChooser(dlg)
  if !isempty(filters)
      makefilters!(dlgp, filters)
  end
  if start_folder != ""
      curr = Gtk4.GLib.G_.file_new_for_path(start_folder)
      Gtk4.G_.set_current_folder(dlgp, GFile(curr))
  end

  function on_response(dlg, response_id)
      if ResponseType(unsafe_trunc(UInt16, response_id)) == ResponseType_ACCEPT
          file = G_.get_file(dlgp)
          sel = GLib.G_.get_path(GFile(file))
      else
          sel = ""
      end
      callback(sel)
      destroy(dlg)
  end

  signal_connect(on_response, dlg, "response")
  show(dlg)

  if timeout > 0
      emit(timer) = on_response(dlg, Int32(Gtk4.ResponseType_CANCEL))
      Timer(emit, timeout)
  end
  return dlg
end

## Other chooser dialogs

function color_dialog(title::AbstractString, parent = nothing; timeout=-1)
    color = Ref{Union{Nothing,_GdkRGBA}}()
    c = Condition()

    color_dialog(title, parent; timeout) do col
        color[] = col
        notify(c)
    end
    wait(c)
    return color[]
end

function color_dialog(callback::Function, title::AbstractString, parent = nothing; timeout=-1)
    dlg = GtkColorChooserDialog(title, parent)

    function on_response(dlg, response_id)
        dlgp = GtkColorChooser(dlg)
        if unsafe_trunc(UInt16, response_id) == ResponseType_OK
            res = G_.get_rgba(dlgp)
        else
            res = nothing
        end
        callback(res)
        destroy(dlg)
    end

    signal_connect(on_response, dlg, "response")
    show(dlg)

    if timeout > 0
        emit(timer) = response(dlg, Gtk4.ResponseType_CANCEL)
        Timer(emit, timeout)
    end
    return dlg
end
