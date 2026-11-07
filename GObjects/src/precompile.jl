# Note: Packages that depend on GObjects should do precompilation with PrecompileTools if possible.
# However, PrecompileTools does not run a package's __init__(), which is pretty essential
# for almost anything in GObjects.jl to work, so we don't use it here.

function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    precompile(Tuple{typeof(GClosureMarshal), Ptr{Nothing}, Ptr{GValue}, UInt32, Ptr{GValue}, Ptr{Nothing}, Ptr{Nothing}})
    precompile(Tuple{typeof(uv_prepare), Ptr{Nothing}, Ptr{Int32}})
    precompile(Tuple{typeof(uv_check), Ptr{Nothing}})
    precompile(Tuple{typeof(uv_dispatch), Ptr{Nothing}, Ptr{Nothing}, Int64})
    precompile(Tuple{typeof(g_yield), UInt64})
    precompile(Tuple{typeof(__init__)})
end
