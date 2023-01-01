## GtkEntry

GtkEntry() = G_.Entry_new()
fraction(progress::GtkEntry) = G_.get_progress_fraction(progress)
fraction(progress::GtkEntry, frac) = G_.set_progress_fraction(progress, frac)
pulse(progress::GtkEntry) = G_.progress_pulse(progress)
pulse_step(progress::GtkEntry, frac) = G_.set_progress_pulse_step(progress, frac)
pulse_step(progress::GtkEntry) = G_.get_progress_pulse_step(progress)

function GtkEntryBuffer(initial_text = nothing)
    G_.EntryBuffer_new(initial_text, -1)
end

GtkEntryCompletionLeaf() = G_.EntryCompletion_new()

complete(completion::GtkEntryCompletion) = G_.complete(completion)

GtkSearchEntry() = G_.SearchEntry_new()

## GtkScale

GtkScale(orientation) = G_.Scale_new(convert(Gtk4.Orientation,orientation), nothing)
GtkScale(orientation, adj::GtkAdjustment) = G_.Scale_new(convert(Gtk4.Orientation,orientation), adj)
GtkScale(orientation, min, max, step) = G_.Scale_new_with_range(convert(Gtk4.Orientation,orientation), min, max, step)
GtkScale(orientation, scale::AbstractRange) = GtkScale(orientation, minimum(scale), maximum(scale), step(scale))
function push!(scale::GtkScale, value, position, markup::AbstractString)
    G_.add_mark(scale, value, convert(Gtk4.PositionType,position), markup)
    scale
end
function push!(scale::GtkScale, value, position)
    G_.add_mark(scale, value, convert(Gtk4.PositionType,position), nothing)
    scale
end
function empty!(scale::GtkScale)
    G_.clear_marks(scale)
    scale
end

## GtkAdjustment

GtkAdjustment(value, lower, upper, step_increment, page_increment, page_size) = G_.Adjustment_new(value, lower, upper, step_increment, page_increment, page_size)

GtkAdjustment(scale::GtkScale) = G_.get_adjustment(scale)

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

GtkSpinButton(adj::GtkAdjustment, climb_rate::Real, digits::Integer) = G_.SpinButton_new(adj,climb_rate,digits)
GtkSpinButton(min::Real, max::Real, step::Real) = G_.SpinButton_new_with_range(min, max, step)
GtkSpinButton(scale::AbstractRange) = GtkSpinButton(minimum(scale), maximum(scale), step(scale))

GtkAdjustment(spinButton::GtkSpinButton) = G_.get_adjustment(spinButton)

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
