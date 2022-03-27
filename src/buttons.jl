GtkButton() = G_.Button_new()
GtkButton(title::AbstractString) = G_.Button_new_with_mnemonic(title)
function GtkButton(w::GtkWidget)
    b = G_.Button_new()
    G_.set_child(b,w)
    b
end

GtkCheckButtonLeaf() = G_.CheckButton_new()
GtkCheckButtonLeaf(title::AbstractString) = G_.CheckButton_new_with_mnemonic(title)

GtkToggleButtonLeaf() = G_.ToggleButton_new()
GtkToggleButtonLeaf(title::AbstractString) = G_.ToggleButton_new_with_mnemonic(title)

GtkSwitchLeaf() = G_.Switch_new()
function GtkSwitchLeaf(active::Bool)
    b = GtkSwitchLeaf()
    G_.set_active(b, active)
    b
end

# GtkRadioButton

GtkLinkButtonLeaf(uri::AbstractString) = G_.LinkButton_new(uri)
GtkLinkButtonLeaf(uri::AbstractString, label::AbstractString) = G_.LinkButton_new_with_label(uri, label)
function GtkLinkButtonLeaf(uri::AbstractString, label::AbstractString, visited::Bool)
    b = GtkLinkButtonLeaf(uri, label)
    G_.set_visited(b, visited)
    b
end
function GtkLinkButtonLeaf(uri::AbstractString, visited::Bool)
    b = GtkLinkButtonLeaf(uri)
    G_.set_visited(b, visited)
    b
end

GtkVolumeButtonLeaf() = G_.VolumeButton_new()
function GtkVolumeButtonLeaf(value::Real) # 0 <= value <= 1
    b = GtkVolumeButtonLeaf()
    G_.set_value(b, value)
    b
end

GtkFontButtonLeaf() = G_.FontButton_new()

GtkColorButtonLeaf() = G_.ColorButton_new()
GtkColorButtonLeaf(color::GdkRGBA) = G_.ColorButton_new_with_rgba(color)
