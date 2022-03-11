
GtkScaleLeaf(vertical::Bool, min, max, step) = G_.Scale_new_with_range(vertical, min, max, step)
GtkScaleLeaf(vertical::Bool, scale::AbstractRange) = GtkScaleLeaf(vertical, minimum(scale), maximum(scale), step(scale))

GtkAdjustmentLeaf(value, lower, upper, step_increment, page_increment, page_size) = G_.Adjustment_new(value, lower, upper, step_increment, page_increment, page_size)

GtkAdjustmentLeaf(scale::GtkScale) = G_.get_adjustment(scale)

GtkSpinButtonLeaf(min, max, step) = G_.SpinButton_new_with_range(min, max, step)
GtkSpinButtonLeaf(scale::AbstractRange) = GtkSpinButtonLeaf(minimum(scale), maximum(scale), step(scale))

GtkAdjustmentLeaf(spinButton::GtkSpinButton) = G_.get_adjustment(spinButton)
