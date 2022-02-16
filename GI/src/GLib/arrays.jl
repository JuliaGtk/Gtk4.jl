struct GArray <: GBoxed
    data::Ptr{UInt8}
    len::UInt32
end

mutable struct GByteArray <: GBoxed
    handle::Ptr{GByteArray}
end

struct _GByteArray
    data::Ptr{UInt8}
    len::UInt32
end

struct GPtrArray <: GBoxed
    pdata::Ptr{Nothing}
    len::UInt32
end
