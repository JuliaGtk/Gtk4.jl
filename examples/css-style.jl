# css-style.jl
# Illustrate setting/changing individual button styles

using Gtk4

css = """
window {
    background-color: teal;
}

button:hover {
    background-color: green;
}

.button2 {
    background: orange;
    color: purple;
    font-style: italic;
}

.button3 {
    background: grey;
    color: red;
    font-size: 18px;
    font-style: normal;
    font-weight: bold;
}

.button4 {
    background: #FFCB05;
    color: #00274C;
}
"""

win = GtkWindow("Colorful Buttons")
cssprov = GtkCssProvider(css)
push!(Gtk4.display(win), cssprov) # applies CSS to all widgets

b1 = GtkButton("Default style")
b2 = GtkButton("Purple italiic")
b3 = GtkButton("Bold red: Click me")
add_css_class(b2, "button2") # goes with ".button2" in css
add_css_class(b3, "button3")

signal_connect(b3, "clicked") do widget
    add_css_class(widget, "button4") # change color on click
    widget.label = "Go Blue" # change label on click
end

box = GtkBox(:v)
win[] = box
push!(box, b1)
push!(box, b2)
push!(box, b3)
