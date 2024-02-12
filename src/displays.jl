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

GtkImage(::Nothing; kwargs...) = error("Ambiguous argument for constructor, please directly call one of the constructors in G_.")
empty!(img::GtkImage) = (G_.clear(img); img)

# GtkPicture (for displaying an image at its natural size)

GtkPicture(::Nothing; kwargs...) = error("Ambiguous argument for constructor, please directly call one of the constructors in G_.")

GtkVideo(::Nothing; kwargs...) = error("Ambiguous argument for constructor, please directly call one of the constructors in G_.")

## GtkLevelBar

## GtkProgressBar

pulse(progress::GtkProgressBar) = G_.pulse(progress)

## GtkSpinner

start(spinner::GtkSpinner) = G_.start(spinner)
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
