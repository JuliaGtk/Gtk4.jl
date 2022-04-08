# generic interface:
export new, width, height, #minsize, maxsize
    reveal, configure, draw, cairo_context,
    visible, destroy, stop, depth, isancestor,
    hide, grab_focus,
    hasparent, toplevel, set_gtk_property!, get_gtk_property,
    selected, hasselection, unselect!, selectall!, unselectall!,
    pagenumber, present, fullscreen, unfullscreen, titlebar,
    maximize, unmaximize, complete, user_action,
    keyval, prev, up, down, popup,
    convert_iter_to_child_iter, convert_child_iter_to_iter,
    pulse, widget,
    buffer, cells, search, place_cursor, select_range, selection_bounds,
    create_mark, scroll_to
    #property, margin, padding, align
    #raise, focus, destroy, enabled

export open_dialog, open_dialog_native, save_dialog, save_dialog_native
export info_dialog, ask_dialog, warn_dialog, error_dialog, input_dialog
export response

# GLib-imported event handling
export signal_connect, signal_handler_disconnect,
    signal_handler_block, signal_handler_unblock, signal_handler_is_connected,
    signal_emit, g_timeout_add, g_idle_add

# Gtk-specific event handling
export signal_emit,
    on_signal_destroy, on_signal_button_press,
    on_signal_button_release, on_signal_motion

export @guarded, @idle_add
