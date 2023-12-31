GtkAdjustment(spinButton::GtkSpinButton) = G_.get_adjustment(spinButton)
GtkAdjustment(range::GtkRange) = G_.get_adjustment(range)
GtkAdjustment(scale::GtkScaleButton) = G_.get_adjustment(scale)

setindex!(buffer::GtkEntryBuffer, content::String, ::Type{String}) =
    G_.set_text(buffer, content, -1)
