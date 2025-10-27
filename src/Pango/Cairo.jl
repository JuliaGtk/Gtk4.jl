module Cairo

using GObjects
const GLib = GObjects

@static if GObjects.libdir == ""
    using Cairo_jll
else
    const libcairo_gobject = joinpath(GObjects.libdir, "libcairo-gobject.so")
end

import Base: convert, unsafe_convert
import CEnum: @cenum, CEnum
import BitFlags: @bitflag

include("../gen/cairo_consts")
include("../gen/cairo_structs")
include("../gen/cairo_functions")

end
