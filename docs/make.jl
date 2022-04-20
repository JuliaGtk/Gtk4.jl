using Documenter, Gtk4

makedocs(
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"
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
                     "manual/canvas.md"
                    ],
        "Gtk.jl to Gtk4.jl" => "diff3to4.md",
        "Reference" => "doc/reference.md",
        #"GI Reference" => "doc/GI_reference.md"
    ],
)

deploydocs(
    repo   = "github.com/JuliaGtk/Gtk4.jl.git",
    target = "build",
    push_preview = true,
    devbranch = "main"
)
