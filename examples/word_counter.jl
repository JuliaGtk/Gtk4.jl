using Gtk4

win = GtkWindow("Word counter")

b = GtkBox(:v)
tv = GtkTextView(; vexpand = true)
l = GtkLabel("0 characters, 0 words, 0 lines")
push!(b, tv)
Gtk4.gutter(tv, :bottom, l)

signal_connect(tv.buffer, "changed") do tb
    charcount = length(tb)
    txt = tb.text
    wordcount = length(split(txt))
    linecount = length(split(txt,"\n"))
    l.label = "$charcount characters, $wordcount words, $linecount lines"
end

win[] = b
show(win)
