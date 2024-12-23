@deprecate GtkAdjustment(spinButton::GtkSpinButton) adjustment(spinButton::GtkSpinButton)
@deprecate GtkAdjustment(range::GtkRange) adjustment(range::GtkRange)
@deprecate GtkAdjustment(scale::GtkScaleButton) adjustment(scale::GtkScaleButton)

setindex!(buffer::GtkEntryBuffer, content::String, ::Type{String}) =
    G_.set_text(buffer, content, -1)

## GtkDialog

function push!(d::GtkDialog, s::AbstractString, response)
    G_.add_button(d, s, Int32(response))
    d
end

function response(widget::GtkDialog, response_id)
    G_.response(widget, Int32(response_id))
end

function GtkDialog(title::AbstractString, buttons, flags, parent = nothing; kwargs...)
    parent = (parent === nothing ? C_NULL : parent)
    w = GtkDialogLeaf(ccall((:gtk_dialog_new_with_buttons, libgtk4), Ptr{GObject},
                (Ptr{UInt8}, Ptr{GObject}, Cint, Ptr{Nothing}),
                            title, parent, flags, C_NULL))
    GObjects.setproperties!(w; kwargs...)
    for (k, v) in buttons
        push!(w, k, v)
    end
    w
end

function GtkMessageDialog(message::AbstractString, buttons, flags, typ, parent = nothing; kwargs...)
    parent = (parent === nothing ? C_NULL : parent)
    w = GtkMessageDialogLeaf(ccall((:gtk_message_dialog_new, libgtk4), Ptr{GObject},
        (Ptr{GObject}, Cuint, Cint, Cint, Ptr{UInt8}),
                                   parent, flags, typ, ButtonsType_NONE, message))
    GObjects.setproperties!(w; kwargs...)
    for (k, v) in buttons
        push!(w, k, v)
    end
    w
end

warn_dialog(callback::Function, message::AbstractString, parent = nothing; timeout = -1) = info_dialog(callback, message, parent; timeout = -1)
error_dialog(callback::Function, message::AbstractString, parent = nothing; timeout = -1) = info_dialog(callback, message, parent; timeout = -1)

@deprecate warn_dialog info_dialog
@deprecate error_dialog info_dialog
