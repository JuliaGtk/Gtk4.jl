module Gtk4

import Base: unsafe_convert, length, size, parent, push!, pushfirst!, insert!,
             pop!, show, length, setindex!, getindex, iterate, eltype, IteratorSize,
             convert, empty!, string, popfirst!, size, delete!, in, close,
             deleteat!, splice!, first, parent, (:), getproperty, setproperty!, copy
@static if VERSION >= v"1.9"
    import Base: stack
end

import CEnum: @cenum
import BitFlags: @bitflag
import ColorTypes: Colorant, RGBA, red, green, blue, alpha

include("GLib/GLib.jl")
include("Pango/Pango.jl")
include("GdkPixbufLib.jl")
include("Graphene.jl")

using ..GLib

using GTK4_jll, Glib_jll
using Xorg_xkeyboard_config_jll, gdk_pixbuf_jll, adwaita_icon_theme_jll, hicolor_icon_theme_jll

using ..GdkPixbufLib
using ..Graphene
using ..Pango

using Preferences

using Reexport
@reexport using Graphics
import .Graphics: width, height, getgc, scale
import Cairo: destroy, show_text, text, status

eval(include("gen/gdk4_consts"))
eval(include("gen/gdk4_structs"))
eval(include("gen/gsk4_consts"))
eval(include("gen/gsk4_structs"))
eval(include("gen/gtk4_consts"))
eval(include("gen/gtk4_structs"))

module G_

using GTK4_jll, Glib_jll

using ..GLib
using ..Pango
using ..Pango.Cairo
using ..Graphene
using ..GdkPixbufLib
using ..Gtk4

eval(include("gen/gdk4_methods"))
eval(include("gen/gdk4_functions"))
eval(include("gen/gtk4_methods"))
eval(include("gen/gtk4_functions"))

function get_current_event_state(instance::GtkEventController)
    ret = ccall(("gtk_event_controller_get_current_event_state", libgtk4), UInt32, (Ptr{GObject},), instance)
    ret2 = ModifierType(ret & Gtk4.MODIFIER_MASK) # there are private values and according to the docs, we are supposed to mask them out
    ret2
end

end

import .GLib: set_gtk_property!, get_gtk_property, run,
              signal_handler_is_connected, signalnames,
              GListModel, start_main_loop, stop_main_loop

# define accessor methods in Gtk4

let skiplist = [:selected_rows, :selected, :selection_bounds, # handwritten methods from Gtk.jl are probably better
            :filter, :string, :first, :error] # conflicts with Base exports
    for func in filter(x->startswith(string(x),"get_"),Base.names(G_,all=true))
        ms=methods(getfield(Gtk4.G_,func))
        v=Symbol(string(func)[5:end])
        v in skiplist && continue
        for m in ms
            GLib.isgetter(m) || continue
            eval(GLib.gen_getter(func,v,m))
        end
    end

    for func in filter(x->startswith(string(x),"set_"),Base.names(G_,all=true))
        ms=methods(getfield(Gtk4.G_,func))
        v=Symbol(string(func)[5:end])
        v in skiplist && continue
        for m in ms
            GLib.issetter(m) || continue
            eval(GLib.gen_setter(func,v,m))
        end
    end
end

include("Gdk4.jl")
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
include("deprecated.jl")
include("basic_exports.jl")

global const lib_version = VersionNumber(
    G_.get_major_version(),
    G_.get_minor_version(),
    G_.get_micro_version())

function set_EGL_vendorlib_dirs(dirs)
    @set_preferences!("EGL_vendorlib_dirs" => dirs)
    @info("Setting will take effect after restarting Julia.")
end

function __init__()
    in("Gtk",[x.name for x in keys(Base.loaded_modules)]) && error("Gtk4 is incompatible with Gtk.")

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

        # Tell libglvnd where to find libEGL
        d = @load_preference("EGL_vendorlib_dirs", "")
        if d != ""
            ENV["__EGL_VENDOR_LIBRARY_DIRS"] = d
        end
    end

    success = ccall((:gtk_init_check, libgtk4), Cint, ()) != 0
    success || error("gtk_init_check() failed.")

    if Sys.islinux() || Sys.isfreebsd()
        G_.set_default_icon_name("julia")
    end

    isinteractive() && GLib.start_main_loop()

    #@debug("Gtk4 initialized.")
end

include("precompile.jl")
_precompile_()

end
