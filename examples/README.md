# Gtk4.jl Examples

## Basic examples
- `calculator4.jl` demonstrates a simple GUI with lots of buttons. Adapted from an example in Gtk.jl by Nand Vinchhi.
- `css.jl` demonstrates widget styling using CSS.
- `css-style.jl` shows how to style individual widgets using CSS classes.
- `dialogs.jl` demonstrates various types of dialogs.
- `show_image.jl` demonstrates how to show a static image using `GtkPicture` and how to copy an image to the clipboard.

## Drawing
- `canvas.jl` demonstrates use of `GtkCanvas`, which allows drawing with [Cairo](https://github.com/JuliaGraphics/Cairo.jl). Also shows how to change the cursor when it's over a certain widget. Adapted from an example in the Gtk.jl manual.
- `canvas_cairomakie.jl` shows how to draw a [CairoMakie](https://github.com/MakieOrg/Makie.jl) plot into a `GtkCanvas`.
- `glarea.jl` shows how to use the `GtkGLArea` widget to draw using OpenGL.

## Lists
- `listview.jl` demonstrates using `GtkListView` to show a huge list of strings.
- `filteredlistview.jl` demonstrates `GtkListView` with a `GtkSearchEntry` and `GtkCustomFilter` to filter what's shown.
- `sortedlistview.jl` demonstrates `GtkListView` with a `GtkDropDown` widget to control how the list is sorted.
- `columnview.jl` demonstrates using `GtkColumnView` to show lists with multiple columns.
- `filteredlistview_tree.jl` demonstrates using `GtkListView` to show a tree. Uses `GtkCustomFilter` to filter what's shown.
- `listbox.jl` demonstrates `GtkListBox` to show a huge list of strings. This widget is a little easier to use than `GtkListView` but may be less performant.

## Multithreading
- `thread.jl` is a basic example of doing work in a separate thread while maintaining a responsive UI. Adapted from an example in the Gtk.jl manual.
- `thread_timeout.jl` adds a label that updates during the task in the example above.

## Applications
- `application.jl` is a simple example of using `GtkApplication` and `GAction`s.
- `application2.jl` together with `application.jl` shows how to use remote actions with DBus. This probably only works on Linux.
- The `ExampleApplication` subdirectory shows how to use Gtk4.jl with [PackageCompiler.jl](https://github.com/JuliaLang/PackageCompiler.jl).

## Toys
- `HDF5Viewer` is a more extended example that shows the contents of an HDF5 file. Uses `GtkBuilder`, `GtkColumnView`, and `GtkTextView` and does some work in a separate thread to keep the UI responsive.

## Experimental

- `custom_widget` shows how to define a custom GtkWidget with its own "snapshot" callback
