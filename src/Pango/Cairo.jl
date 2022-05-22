module Cairo

using ..GLib
using CEnum, BitFlags

eval(include("../gen/cairo_consts"))
eval(include("../gen/cairo_structs"))
eval(include("../gen/cairo_functions"))

end
