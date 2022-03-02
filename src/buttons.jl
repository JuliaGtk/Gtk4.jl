GtkButton() = G_.Button_new()
GtkButton(title::AbstractString) =
    G_.Button_new_with_mnemonic(title)
