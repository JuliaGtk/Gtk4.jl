## GtkEntry

fraction(progress::GtkEntry) = G_.get_progress_fraction(progress)
fraction(progress::GtkEntry, frac) = G_.set_progress_fraction(progress, frac)
pulse(progress::GtkEntry) = G_.progress_pulse(progress)
pulse_step(progress::GtkEntry, frac) = G_.set_progress_pulse_step(progress, frac)
pulse_step(progress::GtkEntry) = G_.get_progress_pulse_step(progress)

"""
    GtkEntryBuffer(initial_text = nothing)

Create an object that holds the text shown in a `GtkEntry`.
"""
function GtkEntryBuffer(initial_text = nothing)
    G_.EntryBuffer_new(initial_text, -1)
end

setindex!(buffer::GtkEntryBuffer, content::String) =
    G_.set_text(buffer, content, -1)

complete(completion::GtkEntryCompletion) = G_.complete(completion)

## GtkScale

"""
    GtkScale(orientation, [scale::AbstractRange]; kwargs...)

Create a scale widget with horizontal (:h) or vertical (:v) orientation and an
optional range. Keyword arguments can be used to set properties.
"""
GtkScale(orientation::Symbol; kwargs...) = GtkScale(convert(Orientation,orientation), nothing; kwargs...)
GtkScale(orientation::Symbol, adj::GtkAdjustment; kwargs...) = GtkScale(convert(Orientation,orientation), adj; kwargs...)
GtkScale(orientation::Symbol, min::Real, max::Real, step::Real; kwargs...) = GtkScale(convert(Orientation,orientation), min, max, step; kwargs...)
GtkScale(orientation, scale::AbstractRange; kwargs...) = GtkScale(convert(Orientation,orientation), minimum(scale), maximum(scale), step(scale); kwargs...)
function push!(scale::GtkScale, value, position, markup::AbstractString)
    G_.add_mark(scale, value, convert(PositionType,position), markup)
    scale
end
function push!(scale::GtkScale, value::Real, position)
    G_.add_mark(scale, value, convert(PositionType,position), nothing)
    scale
end
function empty!(scale::GtkScale)
    G_.clear_marks(scale)
    scale
end

## GtkScaleButton and GtkVolumeButton

GtkScaleButton(min::Real, max::Real, step::Real; kwargs...) = GtkScaleButton(min, max, step, nothing; kwargs...)
GtkScaleButton(scale::AbstractRange; kwargs...) = GtkScaleButton(minimum(scale), maximum(scale), step(scale); kwargs...)

## GtkAdjustment

"""
    configure!(adj::GtkAdjustment; value = nothing, lower = nothing, upper = nothing, step_increment = nothing, page_increment = nothing, page_size = nothing)

Sets all properties of an adjustment, while only resulting in one emission of
the `changed` signal. If an argument is `nothing`, it is not changed.

Related GTK function: [`gtk_adjustment_configure`()]($(gtkdoc_method_url("gtk4","Adjustment","configure")))
"""
function configure!(adj::GtkAdjustment; value = nothing, lower = nothing, upper = nothing, step_increment = nothing, page_increment = nothing, page_size = nothing)
    if value === nothing
        value = G_.get_value(adj)
    end
    if lower === nothing
        lower = G_.get_lower(adj)
    end
    if upper === nothing
        upper = G_.get_upper(adj)
    end
    if step_increment === nothing
        step_increment = G_.get_step_increment(adj)
    end
    if page_increment === nothing
        page_increment = G_.get_page_increment(adj)
    end
    if page_size === nothing
        page_size = G_.get_page_size(adj)
    end
    G_.configure(adj, value, lower, upper, step_increment, page_increment, page_size)
end

## GtkSpinButton
@doc """
    GtkSpinButton(min::Real, max::Real, step::Real; kwargs...)

Create a `GtkSpinButton` widget, which shows an entry and buttons that
increment and decrement the number shown in the entry. Minimum (`min`) and
maximum (`max`) arguments restrict the range of allowable values, while the
`step` argument controls the increment when the widget's buttons are used.
Keyword arguments allow you to set GObject properties.

    GtkSpinButton(adjustment::GtkAdjustment, climb_rate::Real, digits::Integer; kwargs...)

Create a `GtkSpinButton` widget using an `adjustment` to set the range and step
size. Additional arguments set widget properties: `climb_rate` controls the
rate of acceleration when the widget's buttons are held down, while `digits`
controls the number of decimal places displayed.

See also [`GtkAdjustment`](@ref)
and the [GTK docs](https://docs.gtk.org/gtk4/class.SpinButton.html).
""" GtkSpinButton

"""
    GtkSpinButton(scale::AbstractRange; kwargs...)

Create a `GtkSpinButton` with minimum and maximum allowed values and the
default step size corresponding to `scale`.
"""
GtkSpinButton(scale::AbstractRange; kwargs...) = GtkSpinButton(minimum(scale), maximum(scale), step(scale); kwargs...)

"""
    configure!(sb::GtkSpinButton; adj = nothing, climb_rate = nothing, digits = nothing)

Sets the adjustment `adj`, the `climb_rate`, and the number of `digits` of
a `GtkSpinButton`. If an argument is `nothing`, it is not changed.

Related GTK function: [`gtk_spin_button_configure`()]($(gtkdoc_method_url("gtk4","SpinButton","configure")))
"""
function configure!(sb::GtkSpinButton; adj = nothing, climb_rate = nothing, digits = nothing)
    if climb_rate === nothing
        climb_rate = G_.get_climb_rate(sb)
    end
    if digits === nothing
        digits = G_.get_digits(sb)
    end
    G_.configure(sb, adj, climb_rate, digits)
end
