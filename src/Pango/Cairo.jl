module Cairo

using ..GLib
using Cairo_jll

import Base: convert, unsafe_convert
import CEnum: @cenum, CEnum
import BitFlags: @bitflag

include("../gen/cairo_consts")
include("../gen/cairo_structs")
include("../gen/cairo_functions")

end
