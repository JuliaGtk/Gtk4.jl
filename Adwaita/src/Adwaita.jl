module Adwaita

import Base: getindex, setindex!
import CEnum: @cenum
import BitFlags: @bitflag

using Gtk4
using Gtk4.GLib

using libadwaita_jll

eval(include("gen/adw_consts"))
eval(include("gen/adw_structs"))

module G_

using libadwaita_jll

using ..Adwaita
using Gtk4.GLib
using Gtk4.Pango
using Gtk4.Pango.Cairo
using Gtk4.Graphene
using Gtk4.GdkPixbufLib
using Gtk4

eval(include("gen/adw_methods"))
eval(include("gen/adw_functions"))

end

# define accessor methods in Gtk4

let skiplist = [ # handwritten methods are probably better
            ] # conflicts with Base exports
    for func in filter(x->startswith(string(x),"get_"),Base.names(G_,all=true))
        ms=methods(getfield(Adwaita.G_,func))
        v=Symbol(string(func)[5:end])
        v in skiplist && continue
        for m in ms
            GLib.isgetter(m) || continue
            eval(GLib.gen_getter(func,v,m))
        end
    end

    for func in filter(x->startswith(string(x),"set_"),Base.names(G_,all=true))
        ms=methods(getfield(Adwaita.G_,func))
        v=Symbol(string(func)[5:end])
        v in skiplist && continue
        for m in ms
            GLib.issetter(m) || continue
            eval(GLib.gen_setter(func,v,m))
        end
    end
end

function __init__()
    gtype_wrapper_cache_init()
    gboxed_cache_init()
end

getindex(win::AdwWindow) = G_.get_content(win)
getindex(win::AdwApplicationWindow) = G_.get_content(win)
setindex!(win::AdwWindow, widget::GtkWidget) = G_.set_content(win, widget)
setindex!(win::AdwApplicationWindow, widget::GtkWidget) = G_.set_content(win, widget)


end
