module GObjectsTestModule
using Test

@testset "GObjects" begin
if Sys.WORD_SIZE == 64
    include("keyfile.jl")
    include("misc.jl")
end
#include("date.jl")
include("datetime.jl")
#include("gstring.jl")
include("mainloop.jl")
include("list.jl")

include("gvalue.jl")

include("gfile.jl")
include("gmenu.jl")
include("action-group.jl")
end

GC.gc()

sleep(2)

end
