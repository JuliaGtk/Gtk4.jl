module Gtk4

import Base: unsafe_convert, length, size, parent, push!, pushfirst!, insert!,
             pop!, show, length, setindex!, getindex, iterate, eltype, IteratorSize,
             convert, empty!, string, popfirst!, size, delete!, in, close, stack,
             deleteat!, splice!, first, parent, (:), getproperty, setproperty!, copy

import CEnum: @cenum
import BitFlags: @bitflag
import ColorTypes
import ColorTypes: Colorant, RGBA, red, green, blue, alpha
import FixedPointNumbers: N0f8, N0f16

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
import .Graphics: width, height, getgc, scale, center, clip
import Cairo: destroy, text, status

include("gen/gdk4_consts")
include("gen/gdk4_structs")
include("gen/gsk4_consts")
include("gen/gsk4_structs")
include("gen/gtk4_consts")
include("gen/gtk4_structs")

const ModifierType_NONE = ModifierType_NO_MODIFIER_MASK

module G_

using GTK4_jll, Glib_jll

using ..GLib
using ..Pango
using ..Pango.Cairo
using ..Graphene
using ..GdkPixbufLib
using ..Gtk4

using ..Gtk4: BlendMode, Corner, FillRule, GLUniformType, LineCap, LineJoin, MaskMode, PathDirection, PathOperation, RenderNodeType, ScalingFilter, SerializationError, TransformCategory, PathForeachFlags, AxisUse, CrossingMode, DevicePadFeature, DeviceToolType, DmabufError, DragCancelReason, EventType, FullscreenMode, GLError, Gravity, InputSource, KeyMatch, MemoryFormat, NotifyType, ScrollDirection, ScrollUnit, SubpixelLayout, SurfaceEdge, TextureError, TitlebarGesture, TouchpadGesturePhase, VulkanError, AnchorHints, AxisFlags, DragAction, FrameClockPhase, GLAPI, ModifierType, PaintableFlags, SeatCapabilities, ToplevelState, AccessibleAnnouncementPriority, AccessibleAutocomplete, AccessibleInvalidState, AccessiblePlatformState, AccessibleProperty, AccessibleRelation, AccessibleRole, AccessibleSort, AccessibleState, AccessibleTextContentChange, AccessibleTextGranularity, AccessibleTristate, Align, ArrowType, AssistantPageType, BaselinePosition, BorderStyle, BuilderError, ButtonsType, CellRendererAccelMode, CellRendererMode, Collation, ConstraintAttribute, ConstraintRelation, ConstraintStrength, ConstraintVflParserError, ContentFit, CornerType, CssParserError, CssParserWarning, DeleteType, DialogError, DirectionType, EditableProperties, EntryIconPosition, EventSequenceState, FileChooserAction, FileChooserError, FilterChange, FilterMatch, FontLevel, GraphicsOffloadEnabled, IconSize, IconThemeError, IconViewDropPosition, ImageType, InputPurpose, InscriptionOverflow, Justification, LevelBarMode, License, ListTabBehavior, MessageType, MovementStep, NaturalWrapMode, NotebookTab, NumberUpLayout, Ordering, Orientation, Overflow, PackType, PadActionType, PageOrientation, PageSet, PanDirection, PolicyType, PositionType, PrintDuplex, PrintError, PrintOperationAction, PrintOperationResult, PrintPages, PrintQuality, PrintStatus, PropagationLimit, PropagationPhase, RecentManagerError, ResponseType, RevealerTransitionType, ScrollStep, ScrollType, ScrollablePolicy, SelectionMode, SensitivityType, ShortcutScope, ShortcutType, SizeGroupMode, SizeRequestMode, SortType, SorterChange, SorterOrder, SpinButtonUpdatePolicy, SpinType, StackTransitionType, StringFilterMatchMode, SymbolicColor, SystemSetting, TextDirection, TextExtendSelection, TextViewLayer, TextWindowType, TreeViewColumnSizing, TreeViewDropPosition, TreeViewGridLines, Unit, WrapMode, ApplicationInhibitFlags, BuilderClosureFlags, CellRendererState, DebugFlags, DialogFlags, EventControllerScrollFlags, FontChooserLevel, IconLookupFlags, InputHints, ListScrollFlags, PickFlags, PopoverMenuFlags, PrintCapabilities, ShortcutActionFlags, StateFlags, StyleContextPrintFlags, TextSearchFlags

include("gen/gdk4_methods")
include("gen/gdk4_functions")
include("gen/gsk4_methods")
include("gen/gsk4_functions")
include("gen/gtk4_methods")
include("gen/gtk4_functions")

function get_current_event_state(instance::GtkEventController)
    ret = ccall(("gtk_event_controller_get_current_event_state", libgtk4), UInt32, (Ptr{GObject},), instance)
    ret2 = ModifierType(ret & Gtk4.MODIFIER_MASK) # there are private values and according to the docs, we are supposed to mask them out
    ret2
end

end

import .GLib: set_gtk_property!, get_gtk_property, activate,
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

let havechild = [:GtkButton,:GtkCheckButton,:GtkMenuButton,:GtkFrame,:GtkAspectFrame,
                 :GtkExpander,:GtkOverlay,:GtkPopover,:GtkRevealer,:GtkViewport,
                 :GtkSearchBar,:GtkComboBox,:GtkWindow,:GtkScrolledWindow]
    for haschild in havechild
        @eval begin
            getindex(w::$haschild) = G_.get_child(w)
            setindex!(w::$haschild, c::Union{Nothing,GtkWidget}) = G_.set_child(w,c)
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

const lib_version = VersionNumber(
    G_.get_major_version(),
    G_.get_minor_version(),
    G_.get_micro_version())

function set_EGL_vendorlib_dirs(dirs)
    @set_preferences!("EGL_vendorlib_dirs" => dirs)
    @info("Setting will take effect after restarting Julia.")
end

function __init__()
    in("Gtk",[x.name for x in keys(Base.loaded_modules)]) && error("Gtk4 is incompatible with Gtk.")

    if VERSION >= v"1.11" && isinteractive()
        if (Threads.nthreads(:default) > 1 && Threads.nthreads(:interactive) == 0) ||
           Threads.nthreads(:interactive) > 1
            @warn("Gtk4 may freeze the REPL if there is more than one thread in its thread pool. Please set JULIA_NUM_THREADS to N,1 (for N default threads) and restart Julia.")
        end
    end

    # check that GTK is compatible with what the GI generated code expects
    vercheck = G_.check_version(MAJOR_VERSION,MINOR_VERSION,0)
    if vercheck !== nothing
        @warn "Gtk4 version check failed: $vercheck"
    end

    # Set XDG_DATA_DIRS so that Gtk can find its icons and schemas
    ENV["XDG_DATA_DIRS"] = join(filter(x -> x !== nothing, [
        dirname(adwaita_icons_dir),
        dirname(hicolor_icons_dir),
        joinpath(dirname(GTK4_jll.libgtk4_path::String), "..", "share"),
         Base.get(ENV, "XDG_DATA_DIRS", nothing)::Union{String,Nothing},
     ]), Sys.iswindows() ? ";" : ":")

    if !Sys.iswindows()
        # Help GTK find modules for printing, media, and input backends
        # May have consequences for GTK3 programs spawned by Julia
        ENV["GTK_PATH"] = joinpath(dirname(GTK4_jll.libgtk4_path::String),"gtk-4.0")

        # Following also works for finding the printing backends (and also may affect GTK3 programs)
        #ENV["GTK_EXE_PREFIX"] = GTK4_jll.artifact_dir
    end

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

    # prevents warnings from being thrown when using file dialogs
    GLib.G_.set_application_name("julia")
    GLib.G_.set_prgname("julia")

    isinteractive() && GLib.start_main_loop()

    #@debug("Gtk4 initialized.")
end

isinitialized() = G_.is_initialized()

include("precompile.jl")
_precompile_()

end
