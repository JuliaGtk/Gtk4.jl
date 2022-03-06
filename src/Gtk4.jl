module Gtk4

include("GLib/GLib.jl")
include("Pango/Pango.jl")
include("GdkPixbufLib/GdkPixbufLib.jl")

include("Graphene.jl")
include("Gdk4.jl")
include("Gsk4.jl")

using ..GLib

#using JLLWrappers
using GTK4_jll, Glib_jll
using Xorg_xkeyboard_config_jll, gdk_pixbuf_jll, adwaita_icon_theme_jll, hicolor_icon_theme_jll

using ..Gdk4

eval(include("gen/gtk4_consts"))
eval(include("gen/gtk4_structs"))

module G_

using GTK4_jll, Glib_jll

using ..GLib
using ..Gdk4
using ..Pango
using ..Pango.Cairo
using ..Graphene
using ..GdkPixbufLib
using ..Gsk4
using ..Gtk4

eval(include("gen/gtk4_methods"))
# #eval(include("gen/gtk4_functions"))

end

import Base: push!, pushfirst!, insert!, show, length, setindex!, getindex, iterate,
             convert

export parent, hasparent, toplevel, visible, destroy
export show, hide, grab_focus, fullscreen, unfullscreen,
    maximize, unmaximize

include("base.jl")
include("builder.jl")
include("windows.jl")
include("layout.jl")
include("buttons.jl")
include("text.jl")

function gtk_main()
    while true
        ccall((:g_main_context_iteration, GLib.libglib), Cint, (Ptr{Cvoid}, Cint), C_NULL, false)
        sleep(0.005)
    end
end

function __init__()
    # Set XDG_DATA_DIRS so that Gtk can find its icons and schemas
    # ENV["XDG_DATA_DIRS"] = join(filter(x -> x !== nothing, [
    #     dirname(adwaita_icons_dir),
    #     dirname(hicolor_icons_dir),
    #     joinpath(dirname(GTK4_jll.libgtk4_path::String), "..", "share"),
    #      Base.get(ENV, "XDG_DATA_DIRS", nothing)::Union{String,Nothing},
    #  ]), Sys.iswindows() ? ";" : ":")

     gtype_wrapper_cache_init()
#     gboxed_cache_init()
#
#     # Next, ensure that gdk-pixbuf has its loaders.cache file; we generate a
#     # MutableArtifacts.toml file that maps in a loaders.cache we dynamically
#     # generate by running `gdk-pixbuf-query-loaders:`
#     mutable_artifacts_toml = joinpath(dirname(@__DIR__), "MutableArtifacts.toml")
#     loaders_cache_name = "gdk-pixbuf-loaders-cache"
#     #loaders_cache_hash = artifact_hash(loaders_cache_name, mutable_artifacts_toml)
#     #if loaders_cache_hash === nothing
#     #    # Run gdk-pixbuf-query-loaders, capture output,
#     #    loader_cache_contents = gdk_pixbuf_query_loaders() do gpql
#     #        withenv("GDK_PIXBUF_MODULEDIR" => gdk_pixbuf_loaders_dir) do
#     #            return String(read(`$gpql`))
#     #        end
#     #    end
#
#     #    # Write cache out to file in new artifact
#     #    loaders_cache_hash = create_artifact() do art_dir
#     #        open(joinpath(art_dir, "loaders.cache"), "w") do io
#     #            write(io, loader_cache_contents)
#     #        end
#     #    end
#     #    bind_artifact!(mutable_artifacts_toml,
#     #        loaders_cache_name,
#     #        loaders_cache_hash;
#     #        force=true
#     #    )
#     #end
#
#     # Point gdk to our cached loaders
#     #ENV["GDK_PIXBUF_MODULE_FILE"] = joinpath(artifact_path(loaders_cache_hash), "loaders.cache")
#     ENV["GDK_PIXBUF_MODULEDIR"] = gdk_pixbuf_loaders_dir
#
    if Sys.islinux() || Sys.isfreebsd()
        # Needed by xkbcommon:
        # https://xkbcommon.org/doc/current/group__include-path.html.  Related
        # to issue https://github.com/JuliaGraphics/Gtk.jl/issues/469
        ENV["XKB_CONFIG_ROOT"] = joinpath(Xorg_xkeyboard_config_jll.artifact_dir::String,
                                          "share", "X11", "xkb")
    end

    ccall((:gtk_init, libgtk4), Cvoid, ())

    # if g_main_depth > 0, a glib main-loop is already running,
    # so we don't need to start a new one
    if ccall((:g_main_depth, GLib.libglib), Cint, ()) == 0
        ml=ccall((:g_main_loop_new, GLib.libglib), Ptr{Cvoid}, (Ptr{Cvoid}, Cint), C_NULL, true)
        global gtk_main_task = schedule(Task(gtk_main))
    end
end

end
