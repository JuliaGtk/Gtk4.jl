@doc """
    parent(w::GtkWidget)

Returns the parent widget of `w`, or `nothing` if the widget has not been set as
the child of another widget (or is a toplevel widget, like a `GtkWindow`).

See also [`toplevel`](@ref).

Related GTK function: [`gtk_widget_get_parent`()]($(gtkdoc_method_url("gtk4","Widget","get_parent")))
""" parent

"""
    hasparent(w::GtkWidget) -> Bool

Returns `true` if `w` has a parent widget.

See also [`parent`](@ref).
"""
hasparent(w::GtkWidget) = G_.get_parent(w) !== nothing

"""
    toplevel(w::GtkWidget)

Returns the topmost ancestor of `w`, which in most cases will be a `GtkWindow`.

See also [`parent`](@ref).

Related GTK function: [`gtk_widget_get_root`()]($(gtkdoc_method_url("gtk4","Widget","get_root")))
"""
toplevel(w::GtkWidget) = G_.get_root(w)

@doc """
    width(w::GtkWidget)

Returns the allocated width of `w` in pixels.

Related GTK function: [`gtk_widget_get_width`()]($(gtkdoc_method_url("gtk4","Widget","get_width")))
""" width

@doc """
    height(w::GtkWidget)

Returns the allocated height of `w` in pixels.

Related GTK function: [`gtk_widget_get_height`()]($(gtkdoc_method_url("gtk4","Widget","get_height")))
""" height

size(w::GtkWidget) = (width(w), height(w))

"""
    size_request(w::GtkWidget, s)

Set the minimum size `w` to `s`, which should be a tuple (width, height).

Related GTK function: [`gtk_widget_set_size_request`()]($(gtkdoc_method_url("gtk4","Widget","set_size_request")))
"""
size_request(w::GtkWidget, s) = G_.set_size_request(w,s[1],s[2])
size_request(w::GtkWidget, width, height) = G_.set_size_request(w, width, height)

"""
    isvisible(w::GtkWidget) -> Bool

Returns whether `w` and all of its parents are marked as visible.

Related GTK function: [`gtk_widget_is_visible`()]($(gtkdoc_method_url("gtk4","Widget","is_visible")))
"""
isvisible(w::GtkWidget) = G_.is_visible(w)

"""
    visible(w::GtkWidget, state::Bool)

Control visibility of `w`. Note that `w` will not be visible unless its parent
is also visible.

Related GTK function: [`gtk_widget_set_visible`()]($(gtkdoc_method_url("gtk4","Widget","set_visible")))
"""
function visible(w::GtkWidget, state::Bool)
    G_.set_visible(w,state)
end

"""
    show(w::GtkWidget)

Flag `w` to be displayed and return `w`.

Related GTK function: [`gtk_widget_set_visible`()]($(gtkdoc_method_url("gtk4","Widget","set_visible")))
"""
function show(w::GtkWidget)
    G_.set_visible(w, true)
    w
end

"""
    hide(w::GtkWidget)

Flag `w` to be hidden and return `w`. This is the opposite of `show`.

Related GTK function: [`gtk_widget_set_visible`()]($(gtkdoc_method_url("gtk4","Widget","set_visible")))
"""
function hide(w::GtkWidget)
    G_.set_visible(w, false)
    w
end

"""
    grab_focus(w::GtkWidget)

Gives `w` the keyboard focus for the window it is in. Returns `false` if this
fails.

Related GTK function: [`gtk_widget_grab_focus`()]($(gtkdoc_method_url("gtk4","Widget","grab_focus")))
"""
grab_focus(w::GtkWidget) = G_.grab_focus(w)

"""
    isrealized(w::GtkWidget)

Returns whether `w` is realized (that is, whether it has been associated with
a drawing surface).
"""
isrealized(w::GtkWidget) = G_.get_realized(w)

"""
    activate(w::GtkWidget)

Activates widgets like buttons, menu items, etc. that support being activated. Returns `false` if the widget is not activatable.

Related GTK function: [`gtk_widget_activate`()]($(gtkdoc_method_url("gtk4","Widget","activate")))
"""
activate(w::GtkWidget) = G_.activate(w)

"""
    toplevels()
    
Returns a GListModel of all toplevel widgets (i.e. windows) known to GTK4.
"""
toplevels() = G_.get_toplevels()

push!(sg::GtkSizeGroup, w::GtkWidget) = (G_.add_widget(sg, w); sg)
delete!(sg::GtkSizeGroup, w::GtkWidget) = (G_.remove_widget(sg, w); sg)

@doc """
    display(w::GtkWidget)

Gets the `GdkDisplay` for `w`. Should only be called if `w` has been added to
a widget hierarchy.

Related GTK function: [`gtk_widget_get_display`()]($(gtkdoc_method_url("gtk4","Widget","get_display")))
""" display

"""
    monitor(w::GtkWidget)

Gets the `GdkMonitor` where `w` is displayed, or `nothing` if the widget is not
part of a widget hierarchy.
"""
function monitor(w::GtkWidget)
    d = display(w)::GdkDisplayLeaf
    tl = toplevel(w)
    tl === nothing && return nothing
    s = G_.get_surface(GtkNative(tl))::GdkSurfaceLeaf
    # sometimes `get_monitor_at_surface` returns NULL when it shouldn't
    # should be unnecessary in a future version of GTK4_jll: https://gitlab.gnome.org/GNOME/gtk/-/merge_requests/4917
    try
        G_.get_monitor_at_surface(d,s)
    catch e
        nothing
    end
end

"""
    cursor(w::GtkWidget, c)

Sets a cursor `c` when the mouse pointer is over a widget `w`, where `c` can be a `GdkCursor` or a string to specify a name. If `c` is `nothing`, use the default cursor for `w`.

Related GTK functions: [`gtk_widget_set_cursor`()]($(gtkdoc_method_url("gtk4","Widget","set_cursor"))), [`gtk_widget_set_cursor_from_name`()]($(gtkdoc_method_url("gtk4","Widget","set_cursor_from_name")))
"""
function cursor(w::GtkWidget, c::Union{Nothing,GdkCursor})
    G_.set_cursor(w, c)
end

function cursor(w::GtkWidget, n::AbstractString)
    G_.set_cursor_from_name(w, n)
end

@doc """
    cursor(w::GtkWidget)

Gets the cursor `c` for a widget `w`.

Related GTK function: [`gtk_widget_get_cursor`()]($(gtkdoc_method_url("gtk4","Widget","get_cursor")))
""" cursor

function iterate(w::GtkWidget, state=nothing)
    next = (state === nothing ? G_.get_first_child(w) : G_.get_next_sibling(state))
    next === nothing ? nothing : (next, next)
end

eltype(::Type{T}) where T <: GtkWidget = GtkWidget
IteratorSize(::GtkWidget) = Base.SizeUnknown()

convert(::Type{GtkWidget}, w::AbstractString) = GtkLabel(w)

## CSS, style

"""
    GtkCssProvider(data, filename = nothing)

Create a GtkCssProvider object using CSS from a string `data`. If `data` is set to `nothing`, CSS is instead loaded from a file `filename`. If both arguments are `nothing`, an empty GtkCssProvider is returned.

Related GTK functions: [`gtk_css_provider_load_from_path`()]($(gtkdoc_method_url("gtk4","CssProvider","load_from_path"))), [`gtk_css_provider_load_from_data`()]($(gtkdoc_method_url("gtk4","CssProvider","load_from_data")))
"""
function GtkCssProvider(data::Union{AbstractString,Nothing}, filename = nothing)
    provider = G_.CssProvider_new()
    if data !== nothing
        G_.load_from_data(provider, data, -1)
    elseif filename !== nothing
        G_.load_from_path(provider, filename)
    end
    return provider
end

Base.show(io::IO, cssp::GtkCssProvider) = print(io,"GtkCssProviderLeaf(\""*G_.to_string(cssp)*"\")")

function push!(context::GtkStyleContext, provider, priority=STYLE_PROVIDER_PRIORITY_USER)
    G_.add_provider(context, GtkStyleProvider(provider), priority)
    context
end

function push!(display::GdkDisplay, provider, priority=STYLE_PROVIDER_PRIORITY_USER)
    G_.add_provider_for_display(display, GtkStyleProvider(provider), priority)
    display
end

function delete!(context::GtkStyleContext, provider)
    G_.remove_provider(context, GtkStyleProvider(provider))
    context
end

function delete!(display::GdkDisplay, provider)
    G_.remove_provider_for_display(display, GtkStyleProvider(provider))
    display
end

"""
    add_css_class(w::GtkWidget, c::AbstractString)

Add a CSS class to a widget.

See also [`remove_css_class`](@ref).

Related GTK function: [`gtk_widget_add_css_class`()]($(gtkdoc_method_url("gtk4","GtkWidget","add_css_class")))
"""
add_css_class(w::GtkWidget, c::AbstractString) = G_.add_css_class(w, c)

"""
    remove_css_class(w::GtkWidget, c::AbstractString)

Remove a CSS class from a widget.

See also [`add_css_class`](@ref).

Related GTK function: [`gtk_widget_add_css_class`()]($(gtkdoc_method_url("gtk4","GtkWidget","add_css_class")))
"""
remove_css_class(w::GtkWidget, c::AbstractString) = G_.remove_css_class(w, c)

@doc """
    css_classes(w::GtkWidget, c::Vector{AbstractString})

Sets the CSS style classes for a widget, replacing the previously set classes.

Related GTK function: [`gtk_widget_set_css_classes`()]($(gtkdoc_method_url("gtk4","Widget","set_css_classes")))
""" css_classes

# because of a name collision this is annoying to generate using GI
"""
    GtkIconTheme(d::GdkDisplay)

Get the icon theme for a `GdkDisplay`.

Related GTK function: [`gtk_icon_theme_get_for_display`()]($(gtkdoc_method_url("gtk4","IconTheme","get_for_display")))
"""
function GtkIconTheme(d::GdkDisplay)
    ret = ccall(("gtk_icon_theme_get_for_display",libgtk4), Ptr{GObject}, (Ptr{GObject},), d)
    GtkIconThemeLeaf(ret, false)
end

function icon_theme_add_search_path(icon_theme::GtkIconTheme, path::AbstractString)
    G_.add_search_path(icon_theme, path)
end

## GtkApplication and actions

"""
    GtkApplication(id = nothing, flags = GLib.ApplicationFlags_FLAGS_NONE)

Create a `GtkApplication` with DBus id `id` and flags.

Related GTK function: [`gtk_application_new`()]($(gtkdoc_method_url("gtk4","Application","new")))
"""
GtkApplication(id = nothing, flags = GLib.ApplicationFlags_FLAGS_NONE; kwargs...) = GtkApplication(id,flags; kwargs...)
function push!(app::GtkApplication, win::GtkWindow)
    G_.add_window(app, win)
    app
end
function delete!(app::GtkApplication, win::GtkWindow)
    G_.remove_window(app, win)
    app
end

function push!(widget::GtkWidget, group::GActionGroup, name::AbstractString)
    G_.insert_action_group(widget, name, group)
    widget
end

function inhibit(app::GtkApplication, win::GtkWindow, flags, reason)
    cookie = G_.inhibit(app, win, flags, reason)
    if cookie == 0
        error("GtkApplication inhibit failed")
    end
    cookie
end

uninhibit(app::GtkApplication, cookie) = G_.uninhibit(app, cookie)

mutable struct _GtkWidgetClass
    g_type_class::_GTypeClass
    construct_properties::Ptr{GLib._GSList{Ptr{Nothing}}}
    constructor::Ptr{Nothing}
    set_property::Ptr{Cvoid}
    get_property::Ptr{Cvoid}
    dispose::Ptr{Cvoid}
    finalize::Ptr{Cvoid}
    dispatch_properties_changed::Ptr{Cvoid}
    notify::Ptr{Cvoid}
    constructed::Ptr{Cvoid}
    flags::Csize_t
    n_construct_properties::Csize_t
    pspecs::Ptr{Nothing}
    n_pspecs::Csize_t
    pdummy1::Ptr{Nothing}
    pdummy2::Ptr{Nothing}
    pdummy3::Ptr{Nothing}
    show::Ptr{Cvoid}
    hide::Ptr{Cvoid}
    map::Ptr{Cvoid}
    unmap::Ptr{Cvoid}
    realize::Ptr{Cvoid}
    unrealize::Ptr{Cvoid}
    root::Ptr{Cvoid}
    unroot::Ptr{Cvoid}
    size_allocate::Ptr{Cvoid}
    state_flags_changed::Ptr{Cvoid}
    direction_changed::Ptr{Cvoid}
    get_request_mode::Ptr{Cvoid}
    measure::Ptr{Cvoid}
    mnemonic_activate::Ptr{Cvoid}
    grab_focus::Ptr{Cvoid}
    focus::Ptr{Cvoid}
    set_focus_child::Ptr{Cvoid}
    move_focus::Ptr{Cvoid}
    keynav_failed::Ptr{Cvoid}
    query_tooltip::Ptr{Cvoid}
    compute_expand::Ptr{Cvoid}
    css_changed::Ptr{Cvoid}
    system_setting_changed::Ptr{Cvoid}
    snapshot::Ptr{Cvoid}
    contains::Ptr{Cvoid}
    priv::Ptr{Nothing}
    padding::Ptr{Ptr{Nothing}}
end
