# Dialogs

Dialogs are transient windows that show information or ask the user for information.

!!! note "Example"
    Some of the code on this page can be found in "dialogs.jl" in the "example" subdirectory.

## Message dialogs

Gtk4.jl also supports `GtkMessageDialog` and provides several convenience functions:  `info_dialog`, `ask_dialog`, `warn_dialog`, and `error_dialog`.  Each takes a string for a message to show and an optional parent container, and returns nothing, except for `ask_dialog` which returns `true` if the user clicks the button corresponding to `yes`.

For all dialog convenience functions, there are two ways of using them. For use in the REPL or an interactive script, the following forms can be used:

```julia
info_dialog("Julia rocks!")
ask_dialog("Do you like chocolate ice cream?", "Not at all", "I like it") && println("That's my favorite too.")
warn_dialog("Oops!... I did it again")
```
These take an optional argument `timeout` (in seconds) that can be used to make the dialog disappear after a certain time.

In callbacks (for example when a user clocks a button in a GUI), you can use a different form, which takes a callback as the first argument that will be called when the user closes the dialog. This allows the following pattern:
```julia
info_dialog("Julia rocks!") do
   nothing
end
```
or
```julia
ask_dialog("Julia rocks!") do response
   @info println(response)
end
```

## File Dialogs

One of the most common reasons to use a dialog is to allow the user to pick a file to be opened or saved to.
For this Gtk4.jl provides functions `open_dialog` and `save_dialog`.
These use `GtkFileChooserNative`.
The syntax of these functions are similar to the message dialogs:
```julia
open_dialog("Pick a file to open", parent) do filename
   @info filename
end
save_dialog("Pick a file to save", parent) do filename
   @info filename
end
```

If you are using these functions in the context of a GUI, you should set `parent` to be the top-level window.
Otherwise, for standalone usage in scripts, do not set it.

Filters can be used to limit the type of files that the user can pick. Filters can be specified as a Tuple or Vector.
A filter can be specified as a string, in which case it specifies a globbing pattern, for example `"*.png"`.
You can specify multiple match types for a single filter by separating the patterns with a comma, for example `"*.png,*.jpg"`.
You can alternatively specify MIME types, or if no specification is provided it defaults to types supported by `GdkPixbuf`.
The generic specification of a filter is
```julia
GtkFileFilter(; name = nothing, pattern = "", mimetype = "")
```

If on the other hand you want to choose a folder instead of a file, use `select_folder = true` in `open_dialog`:
```julia
dir=Ref{String}()
open_dialog("Select Dataset Folder"; select_folder = true) do name
   dir[] = name
end

if isdir(dir[])
   # do something with dir
end
```

## Custom dialogs

TODO
