convert(::Type{GVariant}, unbox::Ptr{GVariant}) = GVariant(unbox)
unsafe_convert(::Type{Ptr{GVariant}}, w::GVariant) = getfield(w, :handle)

let variant_fns = Expr(:block)
    for i = 1:length(fundamental_types)
        (name, ctype, juliatype, g_value_fn, g_variant_fn) = fundamental_types[i]
        if g_variant_fn !== :error && juliatype != Union{}
            push!(variant_fns.args, :( GVariant(x::T) where {T <: $juliatype} = G_.$(Symbol("Variant_new_", g_variant_fn))(x)))
            if g_variant_fn === :string
                push!(variant_fns.args, :( getindex(gv::GVariant, ::Type{T}) where {T <: $juliatype} = G_.get_string(gv)[1]))
            else
                push!(variant_fns.args, :( getindex(gv::GVariant, ::Type{T}) where {T <: $juliatype} = G_.$(Symbol("get_", g_variant_fn))(gv)))
            end
        end
    end
    Core.eval(GLib, variant_fns)
end

# tuples
function GVariant(x::T) where T <: Tuple
    vs = [GVariant(xi).handle for xi in x]
    G_.Variant_new_tuple(vs)
end
function getindex(gv::GVariant, ::Type{T}) where T <: Tuple
    t=fieldtypes(T)
    if Sys.WORD_SIZE == 64  # GI method doesn't work on 32 bit CPU's -- should probably wrap the ccall by hand instead of this
        n = G_.n_children(gv)
        @assert n == length(t)
    end
    vs = [G_.get_child_value(gv, i-1)[t[i]] for i=1:length(t)]
    tuple(vs...)
end

GVariant(::Type{T},x) where T = GVariant(convert(T, x))

Base.:(==)(lhs::GVariant, rhs::GVariant) = G_.equal(lhs,rhs)
Base.:(<)(lhs::GVariant, rhs::GVariant) = G_.compare(lhs, rhs) < 0
Base.:(<=)(lhs::GVariant, rhs::GVariant) = G_.compare(lhs, rhs) <= 0
Base.:(>)(lhs::GVariant, rhs::GVariant) = G_.compare(lhs, rhs) > 0
Base.:(>=)(lhs::GVariant, rhs::GVariant) = G_.compare(lhs, rhs) >= 0

variant_type_string(::Type{Bool}) = "b"
variant_type_string(::Type{UInt8}) = "y"
variant_type_string(::Type{Int16}) = "n"
variant_type_string(::Type{UInt16}) = "q"
variant_type_string(::Type{Int32}) = "i"
variant_type_string(::Type{UInt32}) = "u"
variant_type_string(::Type{Int64}) = "x"
variant_type_string(::Type{UInt64}) = "t"
variant_type_string(::Type{Float64}) = "d"
variant_type_string(::Type{String}) = "s"
function variant_type_string(::Type{T}) where T <: Tuple
    type_string = "("
    for t in fieldtypes(T)
        type_string *= variant_type_string(t)
    end
    type_string *= ")"
end

function variant_type_string(::Type{T}) where T
    type_string = ""
    if T == Any
        type_string = "*"
    else
        error("Type not implemented")
    end
    # TODO:
    # array
    # maybe
    # dictionary
    type_string
end

GVariantType(t::Type{T}) where T = G_.VariantType_new(variant_type_string(t))

Base.:(==)(lhs::GVariantType, rhs::GVariantType) = G_.equal(lhs,rhs)

function show(io::IO, gvt::GVariantType)
    print(io, "GVariantType(\""*G_.dup_string(gvt)*"\")")
end
