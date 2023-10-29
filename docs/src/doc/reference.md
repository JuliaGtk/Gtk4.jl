# Gtk4 Reference

## Widgets

```@docs
Base.parent
Base.show
Graphics.height
Graphics.width
Gtk4.activate
Gtk4.cursor
Gtk4.grab_focus
Gtk4.hasparent
Gtk4.hide
Gtk4.isvisible
Gtk4.reveal
Gtk4.toplevel
Gtk4.visible
Gtk4.display
Gtk4.monitor
Gtk4.size_request
```

## Windows

```@docs
Gtk4.GtkWindow
Base.close
Cairo.destroy
Gtk4.default_size
Gtk4.fullscreen
Gtk4.unfullscreen
Gtk4.isfullscreen
Gtk4.maximize
Gtk4.unmaximize
Gtk4.present
Gtk4.toplevels
```

## Dialogs
```@docs
Gtk4.ask_dialog
Gtk4.info_dialog
Gtk4.input_dialog
Gtk4.open_dialog
Gtk4.save_dialog
```

## GtkCanvas (drawing with Cairo)

```@docs
Gtk4.GtkCanvas
Gtk4.draw
Graphics.getgc
Gtk4.cairo_surface
```

## GtkGLArea
```@docs
Gtk4.get_error
Gtk4.make_current
Gtk4.queue_render
```

## Event controllers

```@docs
Gtk4.find_controller
Gtk4.widget
```

## GtkTextView

```@docs
Gtk4.buffer
Gtk4.create_mark
Gtk4.place_cursor
Gtk4.scroll_to
Gtk4.search
Gtk4.select_range
Gtk4.selection_bounds
Base.skip
Gtk4.backward_search
Gtk4.buffer_to_window_coords
Gtk4.char_offset
Gtk4.forward_search
Gtk4.text_iter_at_position
Gtk4.window_to_buffer_coords
Gtk4._GtkTextIter
```

