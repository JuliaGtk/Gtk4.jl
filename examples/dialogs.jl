using Gtk4

main_window = GtkWindow("Dialog example")
box = GtkBox(:v)
main_window[]=box
info_dialog_button = GtkButton("Info dialog")
push!(box,info_dialog_button)

function open_info_dialog(b, user_data)
    info_dialog("Here's some information",main_window) do
        nothing
    end
    nothing
end

Gtk4.on_signal_clicked(open_info_dialog, info_dialog_button)

## Question dialog

question_dialog_button = GtkButton("Question dialog")
push!(box,question_dialog_button)

function open_question_dialog(b)
    ask_dialog("May I ask you a question?",main_window) do ans
        @async println("You answered $ans")
    end
end

signal_connect(open_question_dialog,question_dialog_button,"clicked")

## Input dialog

input_dialog_button = GtkButton("Input dialog")
push!(box, input_dialog_button)

function open_input_dialog(b)
    input_dialog("Enter your information", "", main_window) do t
        @async println("response was ",t)
    end
end

signal_connect(open_input_dialog,input_dialog_button,"clicked")

## File open dialog

file_open_dialog_button = GtkButton("File open dialog")
push!(box,file_open_dialog_button)

function open_file_open_dialog(b)
    open_dialog("Select a file to open",main_window) do filename
        @async println("selection was ", filename)
    end
end

signal_connect(open_file_open_dialog,file_open_dialog_button,"clicked")

## File open dialog (multiple)

files_open_dialog_button = GtkButton("Multiple file open dialog")
push!(box,files_open_dialog_button)

function open_files_open_dialog(b)
    open_dialog("Select file(s) to open",main_window; multiple = true) do filenames
        @async println("selection was ", filenames)
    end
end

signal_connect(open_files_open_dialog,files_open_dialog_button,"clicked")

## File open dialog (with a *.png filter)

png_open_dialog_button = GtkButton("PNG open dialog")
push!(box,png_open_dialog_button)

function open_png_open_dialog(b)
    open_dialog("Select a file to open",main_window,["*.png"]) do filename
        @async println("selection was ", filename)
    end
end

signal_connect(open_png_open_dialog,png_open_dialog_button,"clicked")

## File save dialog

file_save_dialog_button = GtkButton("File save dialog")
push!(box,file_save_dialog_button)

function open_file_save_dialog(b)
    save_dialog("Save file",main_window) do filename
        @async println("selection was ", filename)
    end
end

signal_connect(open_file_save_dialog,file_save_dialog_button,"clicked")

## Color chooser dialog

color_dialog_button = GtkButton("Color chooser dialog")
push!(box,color_dialog_button)

function open_color_dialog(b)
    color_dialog("Pick a color",main_window) do selection
        @async println("selection was ",selection)
    end
end

signal_connect(open_color_dialog,color_dialog_button,"clicked")
