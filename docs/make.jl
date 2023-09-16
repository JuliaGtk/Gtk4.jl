using Documenter, Gtk4

makedocs(
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
        size_threshold_ignore = ["doc/GLib_reference.md","doc/reference.md","doc/constants_reference.md"]
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
                     "manual/textwidgets.md",
                     "manual/combobox.md",
                     "manual/listtreeview.md",
                     "manual/dialogs.md",
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
                        "doc/constants_reference.md",
                        "doc/preferences.md"
                    ],
        #"GI Reference" => "doc/GI_reference.md"
    ],
)

deploydocs(
    repo   = "github.com/JuliaGtk/Gtk4.jl.git",
    target = "build",
    push_preview = true,
    devbranch = "main"
)
