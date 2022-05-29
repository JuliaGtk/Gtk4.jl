## GtkButton

GtkButton() = G_.Button_new()
GtkButton(title::AbstractString) = G_.Button_new_with_mnemonic(title)
function GtkButton(w::GtkWidget)
    b = G_.Button_new()
    G_.set_child(b,w)
    b
end

setindex!(f::GtkButton, w::GtkWidget) = G_.set_child(f,w)
getindex(f::GtkButton) = G_.get_child(f)

## GtkCheckButton, GtkToggleButton, GtkSwitch

GtkCheckButton() = G_.CheckButton_new()
GtkCheckButton(title::AbstractString) = G_.CheckButton_new_with_mnemonic(title)

group(cb::GtkCheckButton, cb2::Union{Nothing,GtkCheckButton}) = G_.set_group(cb, cb2)

GtkToggleButton() = G_.ToggleButton_new()
GtkToggleButton(title::AbstractString) = G_.ToggleButton_new_with_mnemonic(title)

group(tb::GtkToggleButton, tb2::Union{Nothing,GtkToggleButton}) = G_.set_group(tb, tb2)

GtkSwitch() = G_.Switch_new()
function GtkSwitch(active::Bool)
    b = GtkSwitch()
    G_.set_active(b, active)
    b
end


GtkLinkButton(uri::AbstractString) = G_.LinkButton_new(uri)
GtkLinkButton(uri::AbstractString, label::AbstractString) = G_.LinkButton_new_with_label(uri, label)
function GtkLinkButton(uri::AbstractString, label::AbstractString, visited::Bool)
    b = GtkLinkButton(uri, label)
    G_.set_visited(b, visited)
    b
end
function GtkLinkButton(uri::AbstractString, visited::Bool)
    b = GtkLinkButton(uri)
    G_.set_visited(b, visited)
    b
end

GtkVolumeButton() = G_.VolumeButton_new()
function GtkVolumeButton(value::Real) # 0 <= value <= 1
    b = GtkVolumeButton()
    G_.set_value(b, value)
    b
end

GtkFontButton() = G_.FontButton_new()

GtkColorButton() = G_.ColorButton_new()
GtkColorButton(color::GdkRGBA) = G_.ColorButton_new_with_rgba(color)

GtkMenuButton() = G_.MenuButton_new()

function GtkPopoverMenu(model::GMenu, nested = false)
    if nested
        G_.PopoverMenu_new_from_model_full(model, PopoverMenuFlags_Nested)
    else
        G_.PopoverMenu_new_from_model(model)
    end
end

GtkPopoverMenuBar(model::GMenu) = G_.PopoverMenuBar_new_from_model(model)

menu(b::Union{GtkMenuButton,GtkPopoverMenu, GtkPopoverMenuBar}, model) = G_.set_menu_model(b, GMenuModel(model))
menu(b::Union{GtkMenuButton,GtkPopoverMenu, GtkPopoverMenuBar}) = G_.get_menu_model(b)
