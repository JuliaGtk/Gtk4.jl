convert(::Type{GVariant}, unbox::Ptr{GVariant}) = GVariant(unbox)
unsafe_convert(::Type{Ptr{GVariant}}, w::GVariant) = getfield(w, :handle)

let variant_fns = Expr(:block)
    for i = 1:length(fundamental_types)
        (name, ctype, juliatype, g_value_fn, g_variant_fn) = fundamental_types[i]
        if g_variant_fn !== :error && juliatype != Union{}
            push!(variant_fns.args, :( GVariant(x::T) where {T <: $juliatype} = G_.$(Symbol("Variant_new_", g_variant_fn))(x)))
            push!(variant_fns.args, :( getindex(gv::GVariant, ::Type{T}) where {T <: $juliatype} = G_.$(Symbol("get_", g_variant_fn))(gv)))
        end
    end
    Core.eval(GLib, variant_fns)
end

GVariant(::Type{T},x) where T = GVariant(convert(T, x))

Base.:(==)(lhs::GVariant, rhs::GVariant) = G_.equal(lhs,rhs)
Base.:(<)(lhs::GVariant, rhs::GVariant) = G_.compare(lhs, rhs) < 0
Base.:(<=)(lhs::GVariant, rhs::GVariant) = G_.compare(lhs, rhs) <= 0
Base.:(>)(lhs::GVariant, rhs::GVariant) = G_.compare(lhs, rhs) > 0
Base.:(>=)(lhs::GVariant, rhs::GVariant) = G_.compare(lhs, rhs) >= 0

function variant_type_string(::Type{T}) where T
    type_string = ""
    if T == Bool
        type_string = "b"
    elseif T == UInt8
        type_string = "y"
    elseif T == Int16
        type_string = "n"
    elseif T == UInt16
        type_string = "q"
    elseif T == Int32
        type_string = "i"
    elseif T == UInt32
        type_string = "u"
    elseif T == Int64
        type_string = "x"
    elseif T == UInt64
        type_string = "t"
    elseif T == Float64
        type_string = "d"
    elseif T == String
        type_string = "s"
    elseif T == Any
        type_string = "*"
    end
    # TODO:
    # array
    # tuple
    # maybe
    # dictionary
    type_string
end

GVariantType(t::Type) where T = G_.VariantType_new(variant_type_string(t))
