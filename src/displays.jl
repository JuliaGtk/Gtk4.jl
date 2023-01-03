"""
    screen_size(widget=nothing)

Returns a tuple `(width,height)` that gives the primary monitor size for the
display where `widget` is being displayed, or the default display if `widget` is
unrealized or not given.
"""
function screen_size(widget=nothing)
    if widget!== nothing && G_.get_realized(widget)
        d=G_.get_display(widget)
    else
        d=G_.get_default() # gdk_display_get_default
        if d===nothing
            error("No default display, no way to return screen_size")
        end
    end

    m=G_.get_monitors(d)
    m===nothing && error("Unable to get list of monitors")
    length(m)==0 && error("No monitors found")
    size(m[1])
end

# GtkImage (for fixed-size images, such as icons)

GtkImage(pixbuf::GdkPixbuf) = G_.Image_new_from_pixbuf(pixbuf)
GtkImage(filename::AbstractString) = G_.Image_new_from_file(filename)

function GtkImage(; filename = nothing, icon_name = nothing)
    source_count = (filename !== nothing) + (icon_name !== nothing)
    @assert(source_count <= 1,
        "GdkPixbuf must have at most one filename or icon_name argument")
    if filename !== nothing
        img = G_.Image_new_from_file(filename)
    elseif icon_name !== nothing
        img = G_.Image_new_from_icon_name(icon_name)
    else
        img = G_.Image_new()
    end
    return img
end
empty!(img::GtkImage) = (G_.clear(img); img)

# GtkPicture (for displaying an image at its natural size)

GtkPicture(pixbuf::GdkPixbuf) = G_.Picture_new_for_pixbuf(pixbuf)
GtkPicture(p::GdkPaintable) = G_.Picture_new_for_paintable(p)
GtkPicture(gfile::GFile) = G_.Picture_new_for_file(gfile)

function GtkPicture(filename = nothing)
    if filename !== nothing
        G_.Picture_new_for_filename(filename)
    else
        G_.Picture_new()
    end
end

## GtkLevelBar

GtkLevelBar() = G_.LevelBar_new()
GtkLevelBar(min_value, max_value) = G_.LevelBar_new_for_interval(min_value, max_value)

## GtkProgressBar

GtkProgressBar() = G_.ProgressBar_new()
pulse(progress::GtkProgressBar) = G_.pulse(progress)

## GtkSpinner

GtkSpinner() = G_.Spinner_new()

start(spinner::GtkSpinner) = G_.start(spinner)
stop(spinner::GtkSpinner) = G_.stop(spinner)

## GtkStatusbar

GtkStatusbar() = G_.Statusbar_new()
context_id(status::GtkStatusbar, source) = G_.get_context_id(status, source)
context_id(status::GtkStatusbar, source::Integer) = source
push!(status::GtkStatusbar, context, text) =
    (G_.push(status, context_id(status, context), text); status)
pop!(status::GtkStatusbar, context) = G_.pop(status, context_id(status, context))
#splice!(status::GtkStatusbar, context, message_id) =
#    G_.remove(status, context_id(status, context), message_id)
empty!(status::GtkStatusbar, context) = (G_.remove_all(status, context_id(status, context)); status)

GtkInfoBar() = G_.InfoBar_new()
