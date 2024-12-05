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

eval(include("../gen/cairo_consts"))
eval(include("../gen/cairo_structs"))
eval(include("../gen/cairo_functions"))

end
