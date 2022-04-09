using Gtk4

main_window = GtkWindow("Dialog example")
box = GtkBox(:v)
main_window[]=box
info_dialog_button = GtkButton("Info dialog")
push!(box,info_dialog_button)

function open_info_dialog(b)
    d = info_dialog("Here's some information",main_window)
    show(d)
end

signal_connect(open_info_dialog,info_dialog_button,"clicked")

question_dialog_button = GtkButton("Question dialog")
push!(box,question_dialog_button)

function get_response(d,id)
    ans = (id == Gtk4.Constants.ResponseType_YES ? "yes" : "no")
    @async println("You answered $ans")
    destroy(d)
end

function open_question_dialog(b)
    d = ask_dialog("May I ask you a question?",main_window)
    signal_connect(get_response,d,"response")
    show(d)
end

signal_connect(open_question_dialog,question_dialog_button,"clicked")

## File open dialog

file_open_dialog_button = GtkButton("File open dialog")
push!(box,file_open_dialog_button)

function get_response(d,id)
    selection = Gtk4.file_chooser_get_selection(d,id)
    @async println("selection was ",selection)
    nothing
end

function open_file_open_dialog(b)
    d = open_dialog("Select a file to open",main_window)
    d.select_multiple = true
    signal_connect(get_response,d,"response")
end

signal_connect(open_file_open_dialog,file_open_dialog_button,"clicked")

## Native file open dialog

file_open_dialog_native_button = GtkButton("File open dialog (native)")
push!(box,file_open_dialog_native_button)

function open_file_open_native_dialog(b)
    d = open_dialog_native("Select a file to open",main_window)
    d.select_multiple = true
    signal_connect(get_response,d,"response")
end

signal_connect(open_file_open_native_dialog,file_open_dialog_native_button,"clicked")

## File save dialog

file_save_dialog_button = GtkButton("File save dialog")
push!(box,file_save_dialog_button)

function open_file_save_dialog(b)
    d = save_dialog("Save file",main_window)
    signal_connect(get_response,d,"response")
end

signal_connect(open_file_save_dialog,file_save_dialog_button,"clicked")

## Native file save dialog

file_save_dialog_native_button = GtkButton("File save dialog (native)")
push!(box,file_save_dialog_native_button)

function open_file_save_native_dialog(b)
    d = save_dialog_native("Save file",main_window)
    signal_connect(get_response,d,"response")
end

signal_connect(open_file_save_native_dialog,file_save_dialog_native_button,"clicked")
