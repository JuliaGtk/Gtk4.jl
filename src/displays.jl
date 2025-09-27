"""
    screen_size(widget=nothing)

Returns a tuple `(width,height)` that gives the primary monitor size for the
display where `widget` is being displayed, or the default display if `widget` is
unrealized or not given.
"""
function screen_size(widget=nothing)::Tuple{Int32,Int32}
    if widget!== nothing && G_.get_realized(widget)
        d=G_.get_display(widget)
    else
        d=G_.get_default() # gdk_display_get_default
        d===nothing && error("No default display, no way to return screen_size")
    end

    m=G_.get_monitors(d)
    m===nothing && error("Unable to get list of monitors")
    ml=m::GListStoreLeaf
    length(ml)==0 && error("No monitors found")
    m1=ml[1]::GdkMonitorLeaf
    size(m1)
end

# GtkImage (for fixed-size images, such as icons)

@doc """
    GtkImage(; kwargs...)
    GtkImage(image::GdkPixbuf; kwargs...)
    GtkImage(image::GdkPaintable; kwargs...)
    GtkImage(image::GIcon; kwargs...)

Create a `GtkImage` widget, which displays an image as an icon. If an `image`
is provided it will be displayed. Keyword arguments allow you to set GObject
properties.

    GtkImage(filename::AbstractString; kwargs...)

Try to load an image from a file and create a `GtkImage` displaying it.

See also the [GTK docs](https://docs.gtk.org/gtk4/class.Picture.html).
""" GtkImage

GtkImage(::Nothing; kwargs...) = error("Ambiguous argument for constructor, please directly call one of the constructors in G_.")
empty!(img::GtkImage) = (G_.clear(img); img)

# GtkPicture (for displaying an image at its natural size)

@doc """
    GtkPicture(; kwargs...)
    GtkPicture(image::GdkPixbuf; kwargs...)
    GtkPicture(image::GdkPaintable; kwargs...)

Create a `GtkPicture` widget, which displays an image at its natural size. If
an `image` is provided it will be displayed. Keyword arguments allow you to
set GObject properties.

    GtkPicture(filename::AbstractString; kwargs...)
    GtkPicture(file::GFile; kwargs...)

Try to load an image from a file and create a `GtkPicture` displaying it.

See also the [GTK docs](https://docs.gtk.org/gtk4/class.Picture.html).
""" GtkPicture


GtkPicture(::Nothing; kwargs...) = error("Ambiguous argument for constructor, please directly call one of the constructors in G_.")

GtkVideo(::Nothing; kwargs...) = error("Ambiguous argument for constructor, please directly call one of the constructors in G_.")

## GtkLevelBar

## GtkProgressBar

@doc """
    GtkProgressBar(; kwargs...)

Create a `GtkProgressBar`, which shows a progress bar and optionally a text
label. Keyword arguments allow you to set GObject properties.

The method or property `fraction` can be used to set or get the fraction of
the operation that is complete (it must be between 0 and 1).

See also the [GTK docs](https://docs.gtk.org/gtk4/class.ProgressBar.html).
""" GtkProgressBar

pulse(progress::GtkProgressBar) = G_.pulse(progress)

## GtkSpinner

@doc """
    GtkSpinner(; kwargs...)

Create a `GtkSpinner`, which optionally shows a spinning icon to indicate to
the user that some operation is running. The state of the widget can be
controlled through the property "spinning" or using the methods `start` and
`stop`. Keyword arguments allow you to set GObject properties.

See also the [GTK docs](https://docs.gtk.org/gtk4/class.Spinner.html).
""" GtkSpinner

"""
    start(spinner::GtkSpinner)

Start a GtkSpinner widget spinning. The purpose of this widget is to show that some operation is in process.

Related GTK function: [`gtk_spinner_start`()]($(gtkdoc_method_url("gtk4","Spinner","start")))
"""
start(spinner::GtkSpinner) = G_.start(spinner)

"""
    stop(spinner::GtkSpinner)

Stop a GtkSpinner. The purpose of this widget is to show that some operation is in process.

Related GTK function: [`gtk_spinner_stop`()]($(gtkdoc_method_url("gtk4","Spinner","stop")))
"""
stop(spinner::GtkSpinner) = G_.stop(spinner)

## GtkStatusbar

context_id(status::GtkStatusbar, source) = G_.get_context_id(status, source)
context_id(status::GtkStatusbar, source::Integer) = source
push!(status::GtkStatusbar, context::Union{Integer,AbstractString}, text::AbstractString) =
    (G_.push(status, context_id(status, context), text); status)
pop!(status::GtkStatusbar, context) = G_.pop(status, context_id(status, context))
#splice!(status::GtkStatusbar, context, message_id) =
#    G_.remove(status, context_id(status, context), message_id)
empty!(status::GtkStatusbar, context) = (G_.remove_all(status, context_id(status, context)); status)
