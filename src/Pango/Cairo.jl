module Cairo

using ..GLib

import CEnum: @cenum, CEnum
import BitFlags: @bitflag, BitFlag

eval(include("../gen/cairo_consts"))
eval(include("../gen/cairo_structs"))
eval(include("../gen/cairo_functions"))

end
