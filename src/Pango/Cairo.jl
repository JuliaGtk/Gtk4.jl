module Cairo

using GObjects
const GLib = GObjects
using Cairo_jll

import Base: convert, unsafe_convert
import CEnum: @cenum, CEnum
import BitFlags: @bitflag

eval(include("../gen/cairo_consts"))
eval(include("../gen/cairo_structs"))
eval(include("../gen/cairo_functions"))

end
