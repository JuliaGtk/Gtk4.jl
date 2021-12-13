# Simple calculator application that utilises Gtk.jl
# created by Nand Vinchhi for GCI 2019

# only works if you use include() in the REPL

using Gtk4, GLib

win = Gtk4.Window()
win.title="Calculator"

b1 = Gtk4.Button_new_with_label("1")
b2 = Gtk4.Button_new_with_label("2")
b3 = Gtk4.Button_new_with_label("3")
b_plus = Gtk4.Button_new_with_label("+")
b4 = Gtk4.Button_new_with_label("4")
b5 = Gtk4.Button_new_with_label("5")
b6 = Gtk4.Button_new_with_label("6")
b_minus = Gtk4.Button_new_with_label("-")
b7 = Gtk4.Button_new_with_label("7")
b8 = Gtk4.Button_new_with_label("8")
b9 = Gtk4.Button_new_with_label("9")
b_multiply = Gtk4.Button_new_with_label("x")
b_clear = Gtk4.Button_new_with_label("C")
b0 = Gtk4.Button_new_with_label("0")
b_equalto = Gtk4.Button_new_with_label("=")
b_divide = Gtk4.Button_new_with_label("÷")

hbox1 = Gtk4.Box(Gtk4.Constants.Orientation_HORIZONTAL,0)
hbox2 = Gtk4.Box(Gtk4.Constants.Orientation_HORIZONTAL,0)
hbox3 = Gtk4.Box(Gtk4.Constants.Orientation_HORIZONTAL,0)
hbox4 = Gtk4.Box(Gtk4.Constants.Orientation_HORIZONTAL,0)

Gtk4.append(hbox1, b1)
Gtk4.append(hbox1, b2)
Gtk4.append(hbox1, b3)
Gtk4.append(hbox1, b_plus)
Gtk4.append(hbox2, b4)
Gtk4.append(hbox2, b5)
Gtk4.append(hbox2, b6)
Gtk4.append(hbox2, b_minus)
Gtk4.append(hbox3, b7)
Gtk4.append(hbox3, b8)
Gtk4.append(hbox3, b9)
Gtk4.append(hbox3, b_multiply)
Gtk4.append(hbox4, b_clear)
Gtk4.append(hbox4, b0)
Gtk4.append(hbox4, b_equalto)
Gtk4.append(hbox4, b_divide)

vbox = Gtk4.Box(Gtk4.Constants.Orientation_VERTICAL,0)
label = Gtk4.Label("")
Gtk4.set_text(label,"")

Gtk4.append(vbox, Gtk4.Label(""))
Gtk4.append(vbox, label)
Gtk4.append(vbox, Gtk4.Label(""))
Gtk4.append(vbox, hbox1)
Gtk4.append(vbox, hbox2)
Gtk4.append(vbox, hbox3)
Gtk4.append(vbox, hbox4)
Gtk4.set_child(win, vbox)

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
        Gtk4.set_text(label, text)
    elseif widget == b2
    	global text = text * "2"
        Gtk4.set_text(label, text)
    elseif widget == b3
        global text = text * "3"
        Gtk4.set_text(label, text)
    elseif widget == b4
    	global text = text * "4"
        Gtk4.set_text(label, text)
    elseif widget == b5
        global text = text * "5"
        Gtk4.set_text(label, text)
    elseif widget == b6
    	global text = text * "6"
        Gtk4.set_text(label, text)
    elseif widget == b7
        global text = text * "7"
        Gtk4.set_text(label, text)
    elseif widget == b8
    	global text = text * "8"
        Gtk4.set_text(label, text)
    elseif widget == b9
        global text = text * "9"
        Gtk4.set_text(label, text)
    elseif widget == b_plus
    	global text = text * " + "
        Gtk4.set_text(label, text)
    elseif widget == b_minus
        global text = text * " - "
        Gtk4.set_text(label, text)
    elseif widget == b_multiply
    	global text = text * " x "
        Gtk4.set_text(label, text)
    elseif widget == b_divide
        global text = text * " ÷ "
        Gtk4.set_text(label, text)
    elseif widget == b0
    	global text = text * "0"
        Gtk4.set_text(label, text)
    elseif widget == b_clear
        global text = ""
        Gtk4.set_text(label, text)
    elseif widget == b_equalto
    	global text = calculate(text)
        Gtk4.set_text(label, text)
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

Gtk4.show(win)
