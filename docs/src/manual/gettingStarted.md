# Getting Started

We start this tutorial with a very simple example that creates an empty window of size 400x200 pixels
and adds a button to it
```julia
using Gtk4

win = GtkWindow("My First Gtk4.jl Program", 400, 200)

b = GtkButton("Click Me")
push!(win,b)

show(win)
```
We will now go through this example step by step. First the package is loaded `using Gtk4` statement. Then a window is created using the `GtkWindow` constructor. It gets as input the window title, the window width, and the window height. Then a button is created using the `GtkButton` constructor. In order to insert the button into the window we call
```julia
push!(win,b)
```
Finally, `show(win)` makes the window visible.
This could also have been accomplished using the `visible` property (properties of "GObjects" like `GtkWindow` are discussed on the [Properties](../manual/properties.md) section of this manual).

## Extended Example

We will now extend the example to let the button actually do something. To this end we first define a callback function that will be executed when the user clicks the button. Our callback function just prints a message.
```julia
function on_button_clicked(w)
  println("The button has been clicked")
end
```
What happens when the user clicks the button is that a "clicked" signal is emitted. In order to connect this signal to our function `on_button_clicked` we have to call
```julia
signal_connect(on_button_clicked, b, "clicked")
```
Our full extended example thus looks like:
```julia
using Gtk4

win = GtkWindow("My First Gtk4.jl Program", 400, 200)

b = GtkButton("Click Me")
push!(win,b)

function on_button_clicked(w)
  println("The button has been clicked")
end
signal_connect(on_button_clicked, b, "clicked")
```

## The hierarchy of widgets

In the example above, `GtkWindow` and `GtkButton` are GTK "widgets", which represent GUI elements. 
Widgets are arranged in a hierarchy, with a `GtkWindow` at the top level (typically), inside which are widgets that contain other widgets.
A widget in this hierarchy can have child widgets and a parent widget.
The parent widget can be found using the method `parent`:
```julia
julia> parent(b) == win
true
```
The toplevel widget in a particular widget's hierarchy can be found using the method `toplevel`:
```julia
julia> toplevel(b) == win
true
```
Iterating over a widget gives you its child widgets:
```julia
for child in widget
    myfunc(child)
end
```

Widgets can be added and removed using interface methods defined by Gtk4.jl.
For many widgets that can contain children, `push!` is defined to append a widget to another's children.
Some widget types can only have one child.
For this situation, Gtk4.jl defines `setindex!(w,x)` and `getindex(w)` methods with no arguments, which can be written as `w[] = x` and `output = w[]`, respectively.
For example, a `GtkWindow` can have only one child widget, so we could have added the button to the window in our example using
```julia
win[] = b
```

