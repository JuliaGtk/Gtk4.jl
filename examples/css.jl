using Gtk4

css="""
window {
    background-color: teal;
}

button {
    background-image: none;
    background: orange;
    color: purple;
    font-style: italic;
}

button:hover {
    background-color: green;
}
"""

win=GtkWindow("My tacky app")

cssprov=GtkCssProvider(data=css)

b=GtkButton("Use default GTK style")
b2=GtkButton("Apply tacky style")

signal_connect(b, "clicked") do widget
    delete!(Gtk4.display(win), cssprov)
end

signal_connect(b2, "clicked") do widget
    push!(Gtk4.display(win), cssprov)
end

box=GtkBox(:v)
win[]=box
push!(box, b)
push!(box, b2)
