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
                     "manual/signals.md",
                     "manual/builder.md",
                     "manual/canvas.md"
                    ],
        "Reference" => "doc/reference.md",
    ],
)

deploydocs(
    repo   = "github.com/JuliaGtk/Gtk4.jl.git",
    target = "build",
    push_preview = true,
    devbranch = "main"
)
