# Simple calculator application that utilises Gtk.jl
# created by Nand Vinchhi for GCI 2019

# only works if you use include() in the REPL

using Gtk4, Gtk4.GLib
import Gtk4.G_

import Gtk4.G_: Button_new_with_label

win = G_.Window()
win.title="Calculator"

b1 = Button_new_with_label("1")
b2 = Button_new_with_label("2")
b3 = Button_new_with_label("3")
b_plus = Button_new_with_label("+")
b4 = Button_new_with_label("4")
b5 = Button_new_with_label("5")
b6 = Button_new_with_label("6")
b_minus = Button_new_with_label("-")
b7 = Button_new_with_label("7")
b8 = Button_new_with_label("8")
b9 = Button_new_with_label("9")
b_multiply = Button_new_with_label("x")
b_clear = Button_new_with_label("C")
b0 = Button_new_with_label("0")
b_equalto = Button_new_with_label("=")
b_divide = Button_new_with_label("÷")

hbox1 = G_.Box(Gtk4.Constants.Orientation_HORIZONTAL,0)
hbox2 = G_.Box(Gtk4.Constants.Orientation_HORIZONTAL,0)
hbox3 = G_.Box(Gtk4.Constants.Orientation_HORIZONTAL,0)
hbox4 = G_.Box(Gtk4.Constants.Orientation_HORIZONTAL,0)

G_.append(hbox1, b1)
G_.append(hbox1, b2)
G_.append(hbox1, b3)
G_.append(hbox1, b_plus)
G_.append(hbox2, b4)
G_.append(hbox2, b5)
G_.append(hbox2, b6)
G_.append(hbox2, b_minus)
G_.append(hbox3, b7)
G_.append(hbox3, b8)
G_.append(hbox3, b9)
G_.append(hbox3, b_multiply)
G_.append(hbox4, b_clear)
G_.append(hbox4, b0)
G_.append(hbox4, b_equalto)
G_.append(hbox4, b_divide)

vbox = G_.Box(Gtk4.Constants.Orientation_VERTICAL,0)
label = G_.Label("")
G_.set_text(label,"")

G_.append(vbox, G_.Label(""))
G_.append(vbox, label)
G_.append(vbox, G_.Label(""))
G_.append(vbox, hbox1)
G_.append(vbox, hbox2)
G_.append(vbox, hbox3)
G_.append(vbox, hbox4)
G_.set_child(win, vbox)

text = ""

function calculate(s)
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


function button_clicked_callback(widget)
	if widget == b1
		global text = text * "1"
        G_.set_text(label, text)
    elseif widget == b2
    	global text = text * "2"
        G_.set_text(label, text)
    elseif widget == b3
        global text = text * "3"
        G_.set_text(label, text)
    elseif widget == b4
    	global text = text * "4"
        G_.set_text(label, text)
    elseif widget == b5
        global text = text * "5"
        G_.set_text(label, text)
    elseif widget == b6
    	global text = text * "6"
        G_.set_text(label, text)
    elseif widget == b7
        global text = text * "7"
        G_.set_text(label, text)
    elseif widget == b8
    	global text = text * "8"
        G_.set_text(label, text)
    elseif widget == b9
        global text = text * "9"
        G_.set_text(label, text)
    elseif widget == b_plus
    	global text = text * " + "
        G_.set_text(label, text)
    elseif widget == b_minus
        global text = text * " - "
        G_.set_text(label, text)
    elseif widget == b_multiply
    	global text = text * " x "
        G_.set_text(label, text)
    elseif widget == b_divide
        global text = text * " ÷ "
        G_.set_text(label, text)
    elseif widget == b0
    	global text = text * "0"
        G_.set_text(label, text)
    elseif widget == b_clear
        global text = ""
        G_.set_text(label, text)
    elseif widget == b_equalto
    	global text = calculate(text)
        G_.set_text(label, text)
    end
end

id1 = signal_connect(button_clicked_callback, b1, "clicked")
id2 = signal_connect(button_clicked_callback, b2, "clicked")
id3 = signal_connect(button_clicked_callback, b3, "clicked")
id4 = signal_connect(button_clicked_callback, b4, "clicked")
id5 = signal_connect(button_clicked_callback, b5, "clicked")
id6 = signal_connect(button_clicked_callback, b6, "clicked")
id7 = signal_connect(button_clicked_callback, b7, "clicked")
id8 = signal_connect(button_clicked_callback, b8, "clicked")
id9 = signal_connect(button_clicked_callback, b9, "clicked")
id10 = signal_connect(button_clicked_callback, b0, "clicked")
id11 = signal_connect(button_clicked_callback, b_plus, "clicked")
id12 = signal_connect(button_clicked_callback, b_minus, "clicked")
id13 = signal_connect(button_clicked_callback, b_multiply, "clicked")
id14 = signal_connect(button_clicked_callback, b_divide, "clicked")
id15 = signal_connect(button_clicked_callback, b_clear, "clicked")
id16 = signal_connect(button_clicked_callback, b_equalto, "clicked")

G_.show(win)
