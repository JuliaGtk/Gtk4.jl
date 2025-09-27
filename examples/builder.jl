using Gtk4

ui = """
<?xml version="1.0" encoding="UTF-8"?>
<interface>
  <requires lib="gtk" version="4.0"/>
  <object class="GtkWindow" id="window1">
    <property name="child">
      <object class="GtkButton" id="button1">
        <property name="label" translatable="yes">button</property>
        <property name="focusable">1</property>
        <property name="receives_default">1</property>
      </object>
    </property>
  </object>
</interface>
"""

function button_clicked(b)
    println("Button clicked")
end

b = GtkBuilder()
push!(b; buffer = ui)
signal_connect(button_clicked, b["button1"], "clicked")

win = b["window1"]
show(win)

