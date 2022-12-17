module Adwaita

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

end
