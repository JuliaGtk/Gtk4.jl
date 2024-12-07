using Documenter, Gtk4, Cairo

function exclude_types(t)
    if t in [Gtk4.GLib.GSimpleAction, Gtk4.GLib.GVariant, Gtk4.GLib.GVariantType, Gtk4.GLib.GApplication]
        return false
    end
    return true
end

makedocs(
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
        size_threshold_ignore = ["doc/Gtk4_types_reference.md", "doc/GLib_types_reference.md", "doc/GLib_reference.md","doc/reference.md","doc/constants_reference.md"]
    ),
    modules = [Gtk4],
    sitename = "Gtk4.jl",
    authors = "...",
    pages = [
        "Home" => "index.md",
        "Manual" => ["manual/gettingStarted.md",
                     "manual/properties.md",
                     "manual/methods.md",
                     "manual/layout.md",
                     "manual/signals.md",
                     "manual/builder.md",
                     "manual/actions.md",
                     "manual/buttons.md",
                     "manual/menus.md",
                     "manual/dialogs.md",
                     "manual/textwidgets.md",
                     "manual/display.md",
                     "manual/combobox.md",
                     "manual/listtreeview.md",
                     "manual/keyevents.md",
                     "manual/canvas.md"
                    ],
        "Howto" => ["howto/nonreplusage.md",
                    "howto/async.md",
                    "howto/sysimage.md"
                    ],
        "Gtk.jl to Gtk4.jl" => "diff3to4.md",
        "Reference" => ["doc/reference.md",
                        "doc/GLib_reference.md",
                        "doc/GObject_reference.md",
                        "doc/Gio_reference.md",
                        "doc/Gtk4_types_reference.md",
                        "doc/GLib_types_reference.md",
                        "doc/constants_reference.md",
                        "doc/preferences.md"
                    ],
        #"GI Reference" => "doc/GI_reference.md"
    ],
    warnonly = true
)

deploydocs(
    repo   = "github.com/JuliaGtk/Gtk4.jl.git",
    target = "build",
    push_preview = true,
    devbranch = "main"
)
