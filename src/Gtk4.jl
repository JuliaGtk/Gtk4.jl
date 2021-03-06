module Gtk4

include("GLib/GLib.jl")
include("Pango/Pango.jl")
include("GdkPixbufLib.jl")

include("Graphene.jl")
include("Gdk4.jl")
include("Gsk4.jl")

using ..GLib

using GTK4_jll, Glib_jll
using Xorg_xkeyboard_config_jll, gdk_pixbuf_jll, adwaita_icon_theme_jll, hicolor_icon_theme_jll
using CEnum, BitFlags

using ..Gdk4
using ..GdkPixbufLib

import Base: unsafe_convert

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
eval(include("gen/gtk4_functions"))

end

global const lib_version = VersionNumber(
      G_.get_major_version(),
      G_.get_minor_version(),
      G_.get_micro_version())

import Base: push!, pushfirst!, insert!, pop!, show, length, setindex!, getindex, iterate, eltype, IteratorSize,
             convert, empty!, string, popfirst!, size, delete!, in,
             deleteat!, splice!, first, parent, (:), getproperty, setproperty!, copy

import .GLib: set_gtk_property!, get_gtk_property, run,
              signal_handler_is_connected

using Reexport
@reexport using Graphics
import .Graphics: width, height, getgc

using Cairo
# import Cairo: destroy


export parent, hasparent, toplevel, visible, destroy
export show, hide, grab_focus, fullscreen, unfullscreen,
    maximize, unmaximize, start, stop, set_child, get_child, select!
export @load_builder
export GtkCanvas

include("base.jl")
include("builder.jl")
include("input.jl")
include("windows.jl")
include("layout.jl")
include("buttons.jl")
include("displays.jl")
include("events.jl")
include("cairo.jl")
include("gl_area.jl")
include("lists.jl")
include("text.jl")
include("tree.jl")
include("basic_exports.jl")

function __init__()
    in(:Gtk, names(Main, imported=true)) && error("Gtk4 is incompatible with Gtk.")

    # Set XDG_DATA_DIRS so that Gtk can find its icons and schemas
    ENV["XDG_DATA_DIRS"] = join(filter(x -> x !== nothing, [
        dirname(adwaita_icons_dir),
        dirname(hicolor_icons_dir),
        joinpath(dirname(GTK4_jll.libgtk4_path::String), "..", "share"),
         Base.get(ENV, "XDG_DATA_DIRS", nothing)::Union{String,Nothing},
     ]), Sys.iswindows() ? ";" : ":")

     gtype_wrapper_cache_init()
     gboxed_cache_init()

    if Sys.islinux() || Sys.isfreebsd()
        # Needed by xkbcommon:
        # https://xkbcommon.org/doc/current/group__include-path.html.  Related
        # to issue https://github.com/JuliaGraphics/Gtk.jl/issues/469
        ENV["XKB_CONFIG_ROOT"] = joinpath(Xorg_xkeyboard_config_jll.artifact_dir::String,
                                          "share", "X11", "xkb")
    end

    ccall((:gtk_init, libgtk4), Cvoid, ())

    GLib.start_main_loop()
end

include("precompile.jl")
_precompile_()

end
