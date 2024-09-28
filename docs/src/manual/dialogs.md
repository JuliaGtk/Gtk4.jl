# Dialogs

Dialogs are transient windows that show messages or ask the user for information.

!!! note "Example"
    Some of the code on this page can be found in "dialogs.jl" in the "example" subdirectory.

!!! tip "Creating dialogs in callbacks"
    When creating dialogs in signal or action callbacks, you must use the methods that take a function as the first argument (or equivalently the `do` syntax).

## Message dialogs

Gtk4.jl wraps `GtkAlertDialog` in convenience functions  `info_dialog` and `ask_dialog`.
Each takes a string for a message to show and an optional parent window, and `ask_dialog` shows two buttons to allow the user to select between two options: "Yes" and "No" by default.

For all dialog convenience functions, there are two ways of using them. For use in the REPL or an interactive script, the following forms can be used:

```julia
info_dialog("Julia rocks!")
ask_dialog("Do you like chocolate ice cream?"; no_text = "Not at all", yes_text = "I like it") && println("That's my favorite too.")
```
Note that `ask_dialog` returns `true` if the user clicks the button corresponding to "yes". The keyword arguments `yes_text` and `no_text` of `ask_dialog` allow you to customize the text for the buttons. These functions take an optional argument `timeout` (in seconds) that can be used to make the dialog disappear after a certain time.

In callbacks (for example when a user clicks a button in a GUI), you **must** use a different form, which takes a callback as the first argument. 
The callback will be called when the user selects an option or closes the dialog. A full example:
```julia
b = GtkButton("Click me")
win = GtkWindow(b,"Info dialog example")
f() = println("message received")
function on_click(b)
    info_dialog(f, "Julia rocks!", win)
end
signal_connect(on_click, b, "clicked")
```
The callback for `info_dialog` should take no arguments, while the callback for `ask_dialog` should take a single boolean argument (which is the user's choice: `true` for "yes", `false` for "no").

If you are using these functions in the context of a GUI, you should set the third argument of `info_dialog`, `parent`, to be the top-level window. The dialog will appear above that window by default (this can be changed by setting the keyword argument `modal` to `false`.

The callback function can alternatively be constructed using Julia's `do` syntax:
```julia
info_dialog("Julia rocks!", win) do
   println("message received")
end
```

## Input dialog

The function `input_dialog` presents a message and a text entry, and it works just like the message dialogs.
The form without a callback argument returns the string entered by the user when the "OK" button is clicked, or an empty string if the dialog is closed or "Cancel" is pressed.

When the form of `input_dialog` with a callback is called (as for example inside callbacks), the callback should take a single string argument.

## File dialogs

A common reason to use a dialog is to allow the user to pick a file to be opened or saved to.
For this Gtk4.jl provides the functions `open_dialog` for choosing an existing file or directory to be opened and `save_dialog` for choosing a filename to be saved to.
These use `GtkFileChooserNative`, which uses the operating system's native dialogs where possible.
The syntax of these functions is similar to the message dialogs.
For a callback in a GUI (for an "Open File" button, for example), you can use
```julia
function f(filename)
   # do something with the file
end

open_dialog(f, "Pick a file to open", parent)
```
The function `f` is called with the file's path as its argument when the user selects the file and clicks "OK".
If the user clicks "Cancel", `f` is called with "" as its argument.
Julia's `do` syntax can be used to construct the function `f` in a convenient way:
```julia
open_dialog("Pick a file to open", parent) do filename
   # call a function here to do something with the file
end
```
Multiple files can be opened by setting the `multiple` keyword argument:
```julia
open_dialog("Pick files to open", parent; multiple = true) do filenames
   # call a function here to do something with files
end
```
In this case `filenames` is a list of paths.

The dialog can be preset to a particular directory using the optional argument `start_folder`:
```julia
open_dialog(f, "Pick a file to open", parent; start_folder = "/data")
```
The same syntax works for `save_dialog`.

If you want to choose a folder instead of a file, use `select_folder = true` in `open_dialog`:
```julia
dir=Ref{String}()
open_dialog("Select Dataset Folder"; select_folder = true) do name
   dir[] = name
end

if isdir(dir[])
   # do something with dir
end
```

### File Filters
Filters can be used to limit the type of files that the user can pick. Filters can be specified as a Tuple or Vector.
A filter can be specified as a string, in which case it specifies a globbing pattern, for example `"*.png"`.
You can specify multiple match types for a single filter by separating the patterns with a comma, for example `"*.png,*.jpg"`.
You can alternatively specify MIME types, or if no specification is provided it defaults to types supported by `GdkPixbuf`.
The generic specification of a filter is
```julia
GtkFileFilter(pattern = "", mimetype = "")
```
A human-readable name can optionally be provided using a keyword argument.

## Custom dialogs

You can define your own type of dialog by creating a window that closes and calls a function when a button is pressed.
For example:
```julia
using Gtk4

function callback_and_destroy(dlg, callback, args...)  # calls the callback and destroys the dialog
    callback(args...)
    Gtk4.transient_for(dlg, nothing)
    destroy(dlg)
end

function custom_dialog(callback::Function, message::AbstractString, parent::GtkWindow)
    dlg = GtkWindow(; modal = true)
    box = GtkBox(:v)
    push!(box, GtkLabel(message))  # or could put other widgets here
    boxb = GtkBox(:h)  # box with buttons for the bottom of the dialog
    push!(box, boxb)
    choice1 = GtkButton("Choice 1"; hexpand = true)
    choice2 = GtkButton("Choice 2"; hexpand = true)
    choice3 = GtkButton("Choice 3"; hexpand = true)
    push!(boxb, choice1)
    push!(boxb, choice2)
    push!(boxb, choice3)
    Gtk4.transient_for(dlg, parent)
    dlg[] = box
    
    signal_connect(choice1, "clicked") do b
        callback_and_destroy(dlg, callback, 1)
    end
    
    signal_connect(choice2, "clicked") do b
        callback_and_destroy(dlg, callback, 2)
    end
    
    signal_connect(choice3, "clicked") do b
        callback_and_destroy(dlg, callback, 3)
    end

    show(dlg)

    return dlg
end

custom_dialog("choice", GtkWindow("parent")) do val
    println("Your choice was $val")
end
```

