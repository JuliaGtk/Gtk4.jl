# Getting Started

We start this tutorial with a very simple example that creates an empty window of size 400x200 pixels
and adds a button to it
```julia
using Gtk4

win = GtkWindow("My First Gtk4.jl Program", 400, 200)

b = GtkButton("Click Me")
push!(win,b)
```
We will now go through this example step by step. First the package is loaded `using Gtk4` statement. Then a window is created using the `GtkWindow` constructor. It gets as input the window title, the window width, and the window height. Then a button is created using the `GtkButton` constructor. In order to insert the button into the window we call
```julia
push!(win,b)
```
Since a `GtkWindow` can have only one child widget, we could have added the button to the window using
```julia
win[] = b
```

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
