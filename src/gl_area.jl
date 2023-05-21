"""
    queue_render(w::GtkGLArea)

Queues a redraw of the widget.

Related GTK function: [`gtk_gl_area_queue_render`()]($(gtkdoc_method_url("gtk4","GtkGLArea","queue_render")))
"""
queue_render(w::GtkGLArea) = G_.queue_render(w)

"""
    make_current(w::GtkGLArea)

Ensures that the `GdkGLContext` used by area is associated with the `GtkGLArea`.

Related GTK function: [`gtk_gl_area_make_current`()]($(gtkdoc_method_url("gtk4","GtkGLArea","make_current")))
"""
make_current(w::GtkGLArea) = G_.make_current(w)

"""
    get_error(w::GtkGLArea)

Gets the current error set on `w`.

Related GTK function: [`gtk_gl_area_get_error`()]($(gtkdoc_method_url("gtk4","GtkGLArea","get_error")))
"""
get_error(w::GtkGLArea) = G_.get_error(w)
