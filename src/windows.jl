@doc """
    GtkWindow(title::Union{Nothing, AbstractString}, w::Real = -1, h::Real = -1, resizable::Bool = true, show_window::Bool = true)

Create an empty `GtkWindow` with a title. A default width and height can be provided with
`w` and `h`.  If `resizable` is false, the window will have a fixed size `w` and `h`. If
`show_window` is false, the window will be initially invisible.

GTK docs: [`GtkWindow`]($(gtkdoc_struc_url("gtk4","Window")))
"""
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

"""
    default_size(win::GtkWindow, w, h)

Set the default size of a `GtkWindow`.

Related GTK function: [`gtk_window_default_size`()]($(gtkdoc_method_url("gtk4","Window","default_size")))
"""
default_size(win::GtkWindow, w, h) = G_.set_default_size(win, w, h)

"""
    isactive(win::GtkWindow)

Returns whether `win` is the currently active toplevel. This is the window that receives
keystrokes.

Related GTK function: [`gtk_window_is_active`()]($(gtkdoc_method_url("gtk4","Window","is_active")))
"""
isactive(win::GtkWindow) = G_.is_active(win)

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

Request that `win` be closed.

Related GTK function: [`gtk_window_close`()]($(gtkdoc_method_url("gtk4","Window","close")))
"""
close(w::GtkWindow) = G_.close(w)

"""
    fullscreen(win::GtkWindow [, mon::GdkMonitor])

Set `win` to fullscreen mode, optionally on a particular monitor `mon.` The windowing
system (outside GTK's control) may not allow this, so it may not work on some platforms.

See also [`unfullscreen`](@ref).

Related GTK functions: [`gtk_window_fullscreen`()]($(gtkdoc_method_url("gtk4","Window","fullscreen"))), [`gtk_window_fullscreen_on_monitor`()]($(gtkdoc_method_url("gtk4","Window","fullscreen_on_monitor")))
"""
fullscreen(win::GtkWindow) = G_.fullscreen(win)
fullscreen(win::GtkWindow, mon::GdkMonitor) = G_.fullscreen_on_monitor(win, mon)

"""
    unfullscreen(win::GtkWindow)

If `win` is in fullscreen mode, return it to normal mode.

See also [`fullscreen`](@ref).

Related GTK function: [`gtk_window_unfullscreen`()]($(gtkdoc_method_url("gtk4","Window","unfullscreen")))
"""
unfullscreen(win::GtkWindow) = G_.unfullscreen(win)

"""
    isfullscreen(win::GtkWindow)

Get whether `win` is in fullscreen mode.

See also [`fullscreen`](@ref).

Related GTK function: [`gtk_window_is_fullscreen`()]($(gtkdoc_method_url("gtk4","Window","is_fullscreen")))
"""
isfullscreen(win::GtkWindow) = G_.is_fullscreen(win)

"""
    issuspended(win::GtkWindow)

Get whether `win` is in a state where it's invisible to the user.

Related GTK function: [`gtk_window_is_suspended`()]($(gtkdoc_method_url("gtk4","Window","is_suspended")))
"""
issuspended(win::GtkWindow) = G_.is_suspended(win)

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
    present(win::GtkWindow [, timestamp])

Presents a window to the user. Usually means move it to the front.

Related GTK function: [`gtk_window_present`()]($(gtkdoc_method_url("gtk4","Window","present")))
Related GTK function: [`gtk_window_present_with_time`()]($(gtkdoc_method_url("gtk4","Window","present_with_time")))
"""
present(win::GtkWindow) = G_.present(win)
present(win::GtkWindow, timestamp) = G_.present_with_time(win, timestamp)

push!(w::GtkWindow, widget::GtkWidget) = (G_.set_child(w, widget); w)
setindex!(w::GtkWindow, widget::Union{Nothing,GtkWidget}) = G_.set_child(w, widget)
getindex(w::GtkWindow) = G_.get_child(w)

# totally ugly hack to salvage this Gtk.jl legacy function for its original purpose
function GObjects.waitforsignal(obj::GtkWindow,signal)
    if signal === :close_request || signal == "close-request"
        c = Condition()
        signal_connect(obj, signal) do w
            notify(c)
            return false
        end
        wait(c)
    else
        invoke(GObjects.waitforsignal, Tuple{GObject,Any}, obj, signal)
    end
end

function push!(wg::GtkWindowGroup, w::GtkWindow)
    G_.add_window(wg,w)
    wg
end
function delete!(wg::GtkWindowGroup, w::GtkWindow)
    G_.remove_window(wg,w)
    wg
end

@doc """
    GtkApplicationWindow(app::GtkApplication, title::AbstractString; kwargs...)

Create an empty `GtkApplicationWindow` for a `GtkApplication` app and a title.
Keyword arguments can be used to set GObject properties.

GTK docs: [`GtkApplicationWindow`]($(gtkdoc_struc_url("gtk4","ApplicationWindow")))
"""
function GtkApplicationWindow(app::GtkApplication, title::AbstractString; kwargs...)
    win = GtkApplicationWindow(app; kwargs...)
    G_.set_title(win, title)
    win
end

setindex!(w::GtkScrolledWindow, widg::Union{Nothing,GtkWidget}) = G_.set_child(w,widg)
getindex(w::GtkScrolledWindow) = G_.get_child(w)

## GtkHeaderBar

push!(hb::GtkHeaderBar, w::GtkWidget) = (G_.pack_end(hb, w); hb)
pushfirst!(hb::GtkHeaderBar, w::GtkWidget) = (G_.pack_start(hb, w); hb)
delete!(hb::GtkHeaderBar, w::GtkWidget) = (G_.remove(hb, w); hb)

"""
    ask_dialog(callback::Function, question::AbstractString, parent = nothing)
    ask_dialog(question::AbstractString, parent = nothing)

Create a dialog with a `question` and two buttons "No" and "Yes". The form with a
`callback` function argument is intended for use in GUI callbacks, while the form without
`callback` is only useful in interactive scripts. If `callback` is provided, it should take
a single boolean argument. This function is called with `true` if "Yes" is selected and
`false` if "No" is selected or the dialog is closed. Passing in a `parent` window is
strongly recommended. The dialog will appear in front of the parent window by default.

Keyword arguments:
- `timeout = -1` to set a time in seconds after which the dialog will close and `false` will be returned. Disabled if negative.
- `no_text = "No"` to change the text for the response that produces `false`.
- `yes_text = "Yes"` to change the text for the response that produces `true`.
- `modal = true` sets whether the dialog is modal (i.e. stays on top of its parent window)
"""
function ask_dialog(question::AbstractString, parent = nothing; timeout = -1, no_text = "No", yes_text = "Yes")
    res = Ref{Bool}(false)
    c = Condition()

    ask_dialog(question, parent; timeout, no_text, yes_text) do res_
        res[] = res_
        notify(c)
    end
    wait(c)
    return res[]
end

function ask_dialog(callback::Function, question::AbstractString, parent = nothing; timeout = -1, no_text = "No", yes_text = "Yes", modal = true)
    dlg = GtkAlertDialog(question; modal = modal)
    G_.set_buttons(dlg, [no_text, yes_text])
    
    cancellable = GObjects.cancel_after_delay(timeout)
    choose(dlg, parent, cancellable) do dlg, resobj
        res = try
            choose_finish(dlg, resobj)
        catch e
            if !isa(e, GObjects.GErrorException)
                rethrow(e)
            end
            0
        end
        callback(Bool(res))
    end
    return dlg
end

"""
    info_dialog(callback::Function, message::AbstractString, parent = nothing)
    info_dialog(message::AbstractString, parent = nothing)

Create a dialog that displays an informational `message`. The form with a `callback`
function argument is intended for use in GUI callbacks, while the form without `callback`
is only useful in interactive scripts. If `callback` is provided, it should take no
arguments. This function is called when the user closes the dialog. If `callback` is not
provided, this function returns when the dialog is closed. Passing in a `parent` window
is strongly recommended. The dialog will appear in front of the parent window by default.

Keyword arguments:
- `timeout = -1` to set a time in seconds after which the dialog will close and `false` will be returned. Disabled if negative.
- `modal = true` sets whether the dialog is modal (i.e. stays on top of its parent window)
""" info_dialog

function info_dialog(message::AbstractString, parent = nothing; timeout = -1)
    c = Condition()
    
    info_dialog(message, parent; timeout) do
        notify(c)
    end
    wait(c)
    return
end

function info_dialog(callback::Function, message::AbstractString, parent = nothing; timeout = -1, modal = true)
    dlg = GtkAlertDialog(message; modal = modal)
    
    function cb(dlg, resobj)
        try
            Gtk4.choose_finish(dlg, resobj)
        catch e
            if !isa(e, GObjects.GErrorException)
                rethrow(e)
            end
        end
        callback()
    end
    
    cancellable = GObjects.cancel_after_delay(timeout)
    choose(cb, dlg, parent, cancellable)
    
    return dlg
end

"""
    input_dialog(callback::Function, message::AbstractString, entry_default::AbstractString, parent = nothing)
    input_dialog(message::AbstractString, entry_default::AbstractString, parent = nothing)

Create a dialog with a `message` and a text entry. The form with a `callback` function
argument is intended for use in GUI callbacks, while the form without `callback` is only
useful in interactive scripts. If `callback` is provided, it should be a function that
takes a single `String` argument. When the "Accept" button is pressed, the callback
function is called with the user's input text. If "Cancel" is pressed (or the dialog or its
parent window `parent` is closed), `entry_default` will be passed to the callback. If no
callback function is provided, the string from the dialog is returned. Passing in a
`parent` window is strongly recommended. The dialog will appear in front of the parent
window by default.

Keyword arguments:
- `timeout = -1` to set a time in seconds after which the dialog will close and `false` will be returned. Disabled if negative.
- `modal = true` sets whether the dialog is modal (i.e. stays on top of its parent window)
"""
function input_dialog(message::AbstractString, entry_default::AbstractString, parent = nothing; timeout = -1, modal = true)
    res = Ref{String}("")
    c = Condition()

    input_dialog(message, entry_default, parent; timeout, modal) do res_
        res[] = res_
        notify(c)
    end
    wait(c)
    return res[]
end

function _callback_and_destroy(dlg, callback, txt)
    callback(txt)
    G_.set_transient_for(dlg, nothing)
    destroy(dlg)
end

function input_dialog(callback::Function, message::AbstractString, entry_default::AbstractString,
                      parent = nothing; timeout = -1, modal = true)
    dlg = GtkWindow()
    box = GtkBox(:v)
    push!(box, GtkLabel(message))
    entry = GtkEntry(; activates_default = true)
    entry.text = entry_default
    push!(box, entry)
    boxb = GtkBox(:h)
    push!(box, boxb)
    accept = GtkButton("Accept"; hexpand = true)
    default_widget(dlg, accept)
    cancel = GtkButton("Cancel"; hexpand = true)
    push!(boxb, cancel)
    push!(boxb, accept)
    isnothing(parent) || (G_.set_transient_for(dlg, parent); G_.set_modal(dlg, modal))
    dlg[] = box
    
    signal_connect(cancel, "clicked") do b
        _callback_and_destroy(dlg, callback, entry_default)
    end
    
    signal_connect(accept, "clicked") do b
        _callback_and_destroy(dlg, callback, text(GtkEditable(entry)))
    end

    show(dlg)

    if timeout > 0
        Timer(timeout) do timer
            _callback_and_destroy(dlg, callback, entry_default)
        end
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
    GObjects.setproperties!(w; kwargs...)
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
    GObjects.setproperties!(filt; kwargs...)
    return filt
end

GtkFileFilter(filter::GtkFileFilter) = filter

function makefilters!(dlgp::GtkFileChooser, filters::Union{AbstractVector, Tuple})
    for f in filters
        G_.add_filter(dlgp, GtkFileFilter(f))
    end
end


function selection(dlg::Union{GtkFileChooserDialog,GtkFileChooserNative}, response_id)
    dlgp = GtkFileChooser(dlg)
    multiple = G_.get_select_multiple(dlgp)
    local sel
    if ResponseType(unsafe_trunc(UInt16, response_id)) == ResponseType_ACCEPT
        if multiple
            filename_list = G_.get_files(dlgp)
            sel = String[GObjects.G_.get_path(GFile(f)) for f in GListModel(filename_list)]
        else
            gfile = G_.get_file(dlgp)
            sel = GObjects.G_.get_path(GFile(gfile))
        end
    else
        if multiple
            sel = String[]
        else
            sel = ""
        end
    end
    return sel
end

## Native file dialogs

show(d::GtkNativeDialog) = G_.show(d)
hide(d::GtkNativeDialog) = G_.hide(d)
destroy(d::GtkNativeDialog) = G_.destroy(d)

"""
    open_dialog(callback::Function, title::AbstractString, parent = nothing, filters::Union{AbstractVector, Tuple} = String[])
    open_dialog(title::AbstractString, parent = nothing, filters::Union{AbstractVector, Tuple} = String[])

Create a dialog for choosing a file or folder to be opened. The form with a `callback`
function argument is intended for use in GUI callbacks, while the form without `callback`
is only useful in interactive scripts. If `callback` is provided, it should be a function
that takes a single `String` argument (or a vector of strings if `multiple` is set to
true). The `callback` is called with the file path chosen by the user or "" if "Cancel" is
pressed. The dialog title is set using `title`. Passing in a `parent` window is strongly
recommended. The dialog will appear in front of the parent window by default. The argument
`filters` can be used to show only directory contents that match certain file extensions.

Keyword arguments:
- `timeout = -1` to set a time in seconds after which the dialog will close and `false` will be returned. Disabled if negative.
- `multiple = false`: if `true`, multiple files can be selected, and an array of file paths is returned rather than a single path.
- `select_folder = false`: set to `true` to allow the user to select a folder rather than a file.  
- `start_folder = ""`: if set to a path, the dialog will start out browsing a particular folder. Otherwise GTK will decide.
"""
function open_dialog(title::AbstractString, parent = nothing, filters::Union{AbstractVector, Tuple} = String[]; timeout = -1, multiple = false, select_folder = false, start_folder = "")
    res = Ref{Union{Vector{String},String}}("")
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
    multiple && G_.set_select_multiple(dlgp, true)
    if !isempty(filters)
        makefilters!(dlgp, filters)
    end
    if start_folder != ""
        curr = GObjects.G_.file_new_for_path(start_folder)
        Gtk4.G_.set_current_folder(dlgp, GFile(curr))
    end

    function on_response(dlg, response_id)
        sel = selection(dlg, response_id)
        callback(sel)
        G_.set_transient_for(dlg, nothing)
        destroy(dlg)
    end

    signal_connect(on_response, dlg, "response")
    show(dlg)

    if timeout > 0
        emit(timer) = on_response(dlg, Int32(ResponseType_CANCEL))
        Timer(emit, timeout)
    end
    return dlg
end

"""
    save_dialog(callback::Function, title::AbstractString, parent = nothing, filters::Union{AbstractVector, Tuple} = String[])
    save_dialog(title::AbstractString, parent = nothing, filters::Union{AbstractVector, Tuple} = String[])

Create a dialog for choosing a file to be saved to. The form with a `callback` function
argument is intended for use in GUI callbacks, while the form without `callback` is only
useful in interactive scripts. If `callback` is provided, it should be a function that
takes a single `String` argument. The `callback` is called with the file path chosen by the
user or "" if "Cancel" is pressed. The window title is set using `title`. Passing in a
`parent` window is strongly recommended. The dialog will appear in front of the parent
window by default. The argument `filters` can be used to show only directory contents that
match certain file extensions.

Keyword arguments:
- `timeout = -1` to set a time in seconds after which the dialog will close and `false` will be returned. Disabled if negative.
- `start_folder = ""`: if set, the dialog will start out browsing a particular folder. Otherwise GTK will decide.
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
      curr = GObjects.G_.file_new_for_path(start_folder)
      Gtk4.G_.set_current_folder(dlgp, GFile(curr))
  end

  function on_response(dlg, response_id)
      if ResponseType(unsafe_trunc(UInt16, response_id)) == ResponseType_ACCEPT
          file = G_.get_file(dlgp)
          sel = GObjects.G_.get_path(GFile(file))
      else
          sel = ""
      end
      callback(sel)
      G_.set_transient_for(dlg, nothing)
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
    color = Ref{Union{Nothing,GdkRGBA}}()
    c = Condition()

    color_dialog(title, parent; timeout) do col
        color[] = col
        notify(c)
    end
    wait(c)
    return color[]
end

function color_dialog(callback::Function, title::AbstractString, parent = nothing; timeout=-1, initial_color = nothing)
    dlg = GtkColorDialog()
    G_.set_title(dlg, title)

    function cb(dlg, resobj)
        rgba = try
            Gtk4.G_.choose_rgba_finish(dlg, GAsyncResult(resobj))
        catch e
            if !isa(e, GObjects.GErrorException)
                rethrow(e)
            end
            nothing
        end
        callback(rgba)
    end

    cancellable = GObjects.cancel_after_delay(timeout)
    G_.choose_rgba(dlg, parent, initial_color, cancellable, cb)

    return dlg
end

## New dialogs (new in GTK 4.10)

function GtkAlertDialog(message::AbstractString; kwargs...)
    ptr = ccall((:gtk_alert_dialog_new, libgtk4), Ptr{GObject}, (Ptr{UInt8},), message)
    d = GtkAlertDialogLeaf(ptr, true)
    GObjects.setproperties!(d; kwargs...)
    d
end

show(dlg::GtkAlertDialog, parent=nothing) = G_.show(dlg, parent)
function choose(cb, dlg::GtkAlertDialog, parent = nothing, cancellable = nothing)
    G_.choose(dlg, parent, cancellable, cb)
end
function choose_finish(dlg, resobj)
    G_.choose_finish(dlg, GAsyncResult(resobj))
end

### New file dialogs

function _path_finish(f, dlg, resobj)
    gfile = f(dlg, GObjects.GAsyncResult(resobj))
    GObjects.path(GObjects.GFile(gfile))
end

function _path_multiple_finish(f, dlg, resobj)
    gfiles = f(dlg, GObjects.GAsyncResult(resobj))
    [GObjects.path(GObjects.GFile(gfile)) for gfile in gfiles]
end

"""
    GtkFileDialog(; kwargs...)

# Selected keyword arguments

- accept_label: the text to show on the dialog's accept button
- default_filter: the `GtkFileFilter` initially active in the file dialog
- filters: a GListModel of file filters
- initial_name: the filename or directory that is initially selected in the file chooser dialog
- title: the title of the dialog
- modal: whether the dialog is modal
""" GtkFileDialog(; kwargs...)

"""
    save(cb, dlg::GtkFileDialog, parent = nothing, cancellable = nothing)

Open a dialog to save a file. The callback `cb` will be called when the user
selects a file.
"""
function Graphics.save(cb, dlg::GtkFileDialog, parent = nothing, cancellable = nothing)
    G_.save(dlg, parent, cancellable, cb)
end

"""
    save_path(dlg, resobj)

Get the path selected by the user in a save dialog. An exception will be thrown
if the user cancelled the operation.
"""
save_path(dlg, resobj) = _path_finish(Gtk4.G_.save_finish, dlg, resobj)

"""
    open_file(cb, dlg::GtkFileDialog, parent = nothing, cancellable = nothing)

Open a dialog to open a file. The callback `cb` will be called when the user
selects a file.
"""
function open_file(cb, dlg::GtkFileDialog, parent = nothing, cancellable = nothing)
    G_.open(dlg, parent, cancellable, cb)
end

"""
    open_path(dlg, resobj)

Get the path selected by the user in an open dialog.
"""
open_path(dlg, resobj) = _path_finish(Gtk4.G_.open_finish, dlg, resobj)

"""
    select_folder(cb, dlg::GtkFileDialog, parent = nothing, cancellable = nothing)

Open a dialog to select a folder. The callback `cb` will be called when the user
selects a folder.
"""
function select_folder(cb, dlg::GtkFileDialog, parent = nothing, cancellable = nothing)
    G_.select_folder(dlg, parent, cancellable, cb)
end

"""
    select_folder_path(dlg, resobj)

Get the path selected by the user in a select folder dialog.
"""
select_folder_path(dlg, resobj) = _path_finish(Gtk4.G_.select_folder_finish, dlg, resobj)

"""
    open_multiple(cb, dlg::GtkFileDialog, parent = nothing, cancellable = nothing)

Open a dialog to open multiple files. The callback `cb` will be called when the user
is done selecting files.
"""
function open_multiple(cb, dlg::GtkFileDialog, parent = nothing, cancellable = nothing)
    G_.open_multiple(dlg, parent, cancellable, cb)
end

"""
    open_paths(dlg, resobj)

Get the paths selected by the user in a "open multiple" dialog.
"""
open_paths(dlg, resobj) = _path_multiple_finish(Gtk4.G_.open_multiple_finish, dlg, resobj)

"""
    select_multiple_folders(cb, dlg::GtkFileDialog, parent = nothing, cancellable = nothing)

Open a dialog to select multiple folders. The callback `cb` will be called when the user
is done selecting folders.
"""
function select_multiple_folders(cb, dlg::GtkFileDialog, parent = nothing, cancellable = nothing)
    G_.select_multiple_folders(dlg, parent, cancellable, cb)
end

"""
    select_multiple_folder_paths(dlg, resobj)

Get the paths selected by the user in a "select multiple folders" dialog.
"""
select_multiple_folder_paths(dlg, resobj) = _path_multiple_finish(Gtk4.G_.select_multiple_folders_finish, dlg, resobj)

function choose_font(cb, dlg::GtkFontDialog, parent = nothing, cancellable = nothing)
    G_.choose_font(dlg, parent, nothing, cancellable, cb)
end

font(dlg, resobj) = G_.choose_font_finish(dlg, GAsyncResult(resobj))
