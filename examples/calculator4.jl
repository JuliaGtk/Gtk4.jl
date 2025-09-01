# Simple calculator application that utilises Gtk.jl
# created by Nand Vinchhi for GCI 2019, later ported to Gtk4.jl

# only works if you use include() in the REPL

using Gtk4, Gtk4.GLib

win = GtkWindow("Calculator")

b1 = GtkButton("1")
b2 = GtkButton("2")
b3 = GtkButton("3")
b_plus = GtkButton("+")
b4 = GtkButton("4")
b5 = GtkButton("5")
b6 = GtkButton("6")
b_minus = GtkButton("-")
b7 = GtkButton("7")
b8 = GtkButton("8")
b9 = GtkButton("9")
b_multiply = GtkButton("x")
b_clear = GtkButton("C")
b0 = GtkButton("0")
b_equalto = GtkButton("=")
b_divide = GtkButton("÷")

hbox1 = push!(GtkBox(:h), b1, b2, b3, b_plus)
hbox2 = push!(GtkBox(:h), b4, b5, b6, b_minus)
hbox3 = push!(GtkBox(:h), b7, b8, b9, b_multiply)
hbox4 = push!(GtkBox(:h), b_clear, b0, b_equalto, b_divide)

vbox = GtkBox(:v)
label = GtkLabel("")

push!(vbox, GtkLabel(""), label, GtkLabel(""), hbox1, hbox2, hbox3, hbox4)
win[] = vbox

function calculate(s)
    isempty(s) && return ""
    x = "+ " * s
    k = split(x)
    final = 0

    for i = 1:length(k)
        if k[i] == "+"
            final += parse(Float64, k[i + 1])
        elseif k[i] == "-"
            final -= parse(Float64, k[i + 1])
        elseif k[i] == "x"
            final *= parse(Float64, k[i + 1])
        elseif k[i] == "÷"
            final /= parse(Float64, k[i + 1])
        end
    end
    return string(final)
end

append_str(str) = label.label *= str
append_1(widget) = append_str("1")
append_2(widget) = append_str("2")
append_3(widget) = append_str("3")
append_4(widget) = append_str("4")
append_5(widget) = append_str("5")
append_6(widget) = append_str("6")
append_7(widget) = append_str("7")
append_8(widget) = append_str("8")
append_9(widget) = append_str("9")
append_0(widget) = append_str("0")
append_plus(widget) = append_str(" + ")
append_minus(widget) = append_str(" - ")
append_times(widget) = append_str(" x ")
append_div(widget) = append_str(" ÷ ")
clear_callback(widget) = label.label = ""
calc_callback(widget) = label.label = calculate(label.label)

signal_connect(append_1, b1, "clicked")
signal_connect(append_2, b2, "clicked")
signal_connect(append_3, b3, "clicked")
signal_connect(append_4, b4, "clicked")
signal_connect(append_5, b5, "clicked")
signal_connect(append_6, b6, "clicked")
signal_connect(append_7, b7, "clicked")
signal_connect(append_8, b8, "clicked")
signal_connect(append_9, b9, "clicked")
signal_connect(append_0, b0, "clicked")
signal_connect(append_plus, b_plus, "clicked")
signal_connect(append_minus, b_minus, "clicked")
signal_connect(append_times, b_multiply, "clicked")
signal_connect(append_div, b_divide, "clicked")
signal_connect(clear_callback, b_clear, "clicked")
signal_connect(calc_callback, b_equalto, "clicked")
