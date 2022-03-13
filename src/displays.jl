GtkProgressBarLeaf() = G_.ProgressBar_new()
pulse(progress::GtkProgressBar) = G_.pulse(progress)

GtkSpinnerLeaf() = G_.Spinner_new()

start(spinner::GtkSpinner) = G_.start(spinner)
stop(spinner::GtkSpinner) = G_.stop(spinner)

GtkStatusbarLeaf() = G_.Statusbar_new()
context_id(status::GtkStatusbar, source) = G_.get_context_id(status, source)
context_id(status::GtkStatusbar, source::Integer) = source
push!(status::GtkStatusbar, context, text) =
    (G_.push(status, context_id(status, context), text); status)
pop!(status::GtkStatusbar, context) = G_.pop(status, context_id(status, context))
slice!(status::GtkStatusbar, context, message_id) =
    G_.remove(status, context_id(status, context), message_id)
empty!(status::GtkStatusbar, context) = G_.remove_all(status, context_id(status, context))
