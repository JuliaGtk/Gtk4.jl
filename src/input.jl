## GtkEntry

GtkEntry() = G_.Entry_new()
fraction(progress::GtkEntry) = G_.get_progress_fraction(progress)
fraction(progress::GtkEntry, frac) = G_.set_progress_fraction(progress, frac)
pulse(progress::GtkEntry) = G_.progress_pulse(progress)
pulse_step(progress::GtkEntry, frac) = G_.set_progress_pulse_step(progress, frac)
pulse_step(progress::GtkEntry) = G_.get_progress_pulse_step(progress)

GtkEntryCompletionLeaf() = G_.EntryCompletion_new()

complete(completion::GtkEntryCompletion) = G_.complete(completion)

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
empty!(scale::GtkScale) = G_.clear_marks(scale)

## GtkAdjustment

GtkAdjustment(value, lower, upper, step_increment, page_increment, page_size) = G_.Adjustment_new(value, lower, upper, step_increment, page_increment, page_size)

GtkAdjustment(scale::GtkScale) = G_.get_adjustment(scale)

## GtkSpinButton

GtkSpinButton(adj::GtkAdjustment, climb_rate::Real, digits::Integer) = G_.SpinButton_new(adj,climb_rate,digits)
GtkSpinButton(min::Real, max::Real, step::Real) = G_.SpinButton_new_with_range(min, max, step)
GtkSpinButton(scale::AbstractRange) = GtkSpinButton(minimum(scale), maximum(scale), step(scale))

GtkAdjustment(spinButton::GtkSpinButton) = G_.get_adjustment(spinButton)
