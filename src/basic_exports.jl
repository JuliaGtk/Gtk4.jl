# generic interface:
export width, height, set_child, get_child,
    reveal, configure!, draw, cairo_context,
    visible, isvisible, destroy, start, stop, depth, isancestor,
    hide, show, grab_focus, activate,
    hasparent, parent, toplevel, set_gtk_property!, get_gtk_property,
    selected, hasselection, select!, unselect!, selectall!, unselectall!, selected_rows,
    pagenumber, present, fullscreen, unfullscreen, titlebar,
    maximize, unmaximize, complete, user_action, stack,
    add_overlay, remove_overlay,
    prev, next, up, down, popup, menubar,
    convert_iter_to_child_iter, convert_child_iter_to_iter, index_from_iter,
    pulse, fraction, pulse_step, widget, group, expand_to_path,
    buffer, cells, search, place_cursor, select_range, selection_bounds,
    create_mark, scroll_to, cursor, @load_builder,
    queue_render, make_current, get_error
    #margin, padding, align
    #raise, focus, enabled

export resize, GtkCanvas

export open_dialog, save_dialog
export info_dialog, ask_dialog, warn_dialog, error_dialog, input_dialog
export color_dialog
export response

export GListModel, changed

# GLib-imported event handling
export signal_connect, signal_handler_disconnect,
    signal_handler_block, signal_handler_unblock, signal_handler_is_connected,
    signal_emit, g_timeout_add, g_idle_add
export @guarded, @idle_add
export start_main_loop, stop_main_loop

# Gtk-specific event handling
export signal_emit,
    on_signal_destroy

# Gdk info and manipulation
export screen_size
