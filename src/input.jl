GtkEntryLeaf() = G_.Entry_new()

GtkEntryCompletionLeaf() = G_.EntryCompletion_new()

complete(completion::GtkEntryCompletion) = G_complete(completion)

GtkScaleLeaf(vertical::Bool, min, max, step) = G_.Scale_new_with_range(vertical, min, max, step)
GtkScaleLeaf(vertical::Bool, scale::AbstractRange) = GtkScaleLeaf(vertical, minimum(scale), maximum(scale), step(scale))
# function push!(scale::GtkScale, value, position::Symbol, markup::AbstractString)
#     G_.add_mark(scale, value, GtkPositionType.(position), markup)
#     scale
# end
# function push!(scale::GtkScale, value, position::Symbol)
#     G_.add_mark(scale, value, GtkPositionType.(position), C_NULL)
#     scale
# end
empty!(scale::GtkScale) = G_.clear_marks(scale)

GtkAdjustmentLeaf(value, lower, upper, step_increment, page_increment, page_size) = G_.Adjustment_new(value, lower, upper, step_increment, page_increment, page_size)

GtkAdjustmentLeaf(scale::GtkScale) = G_.get_adjustment(scale)

GtkSpinButtonLeaf(min, max, step) = G_.SpinButton_new_with_range(min, max, step)
GtkSpinButtonLeaf(scale::AbstractRange) = GtkSpinButtonLeaf(minimum(scale), maximum(scale), step(scale))

GtkAdjustmentLeaf(spinButton::GtkSpinButton) = G_.get_adjustment(spinButton)
