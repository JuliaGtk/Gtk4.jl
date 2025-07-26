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
        <signal name="clicked" handler="button_clicked" swapped="no" />
      </object>
    </property>
  </object>
</interface>
"""

function button_clicked(b)
    println("I have been clicked")
end

b = GtkBuilder(Main)
push!(b; buffer = ui)

win = b["window1"]
show(win)

