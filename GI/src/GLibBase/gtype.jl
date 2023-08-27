abstract type GTypeInstance end
abstract type GObject <: GTypeInstance end
abstract type GInterface <: GObject end
abstract type GBoxed  end

const  GEnum = Int32
const  GType = Csize_t

struct GParamSpec
  g_type_instance::Ptr{Nothing}
  name::Ptr{UInt8}
  flags::Cint
  value_type::GType
  owner_type::GType
end

const fundamental_types = (
    #(:name,      Ctype,            JuliaType,      g_value_fn)
    (:invalid,    Nothing,          Union{},        :error),
    (:void,       Nothing,          Nothing,        :error),
    (:GInterface, Ptr{Nothing},     GInterface,     :error),
    (:gchar,      Int8,             Int8,           :schar),
    (:guchar,     UInt8,            UInt8,          :uchar),
    (:gboolean,   Cint,             Bool,           :boolean),
    (:gint,       Cint,             Union{},        :int),
    (:guint,      Cuint,            Union{},        :uint),
    (:glong,      Clong,            Union{},        :long),
    (:gulong,     Culong,           Union{},        :ulong),
    (:gint64,     Int64,            Signed,         :int64),
    (:guint64,    UInt64,           Unsigned,       :uint64),
    (:GEnum,      GEnum,            Union{},        :enum),
    (:GFlags,     GEnum,            Union{},        :flags),
    (:gfloat,     Float32,          Float32,        :float),
    (:gdouble,    Float64,          AbstractFloat,  :double),
    (:gchararray, Ptr{UInt8},       AbstractString, :string),
    (:gpointer,   Ptr{Nothing},     Ptr,            :pointer),
    (:GBoxed,     Ptr{GBoxed},      GBoxed,         :boxed),
    (:GParamSpec, Ptr{GParamSpec},  Ptr{GParamSpec},:param),
    (:GObject,    Ptr{GObject},     GObject,        :object),
    (:GType,      Ptr{GType},       GType,          :type),
    (:GVariant,   Ptr{GVariant},    GVariant,       :variant),
    )
# NOTE: in general do not cache ids, except for these fundamental values
g_type_from_name(name::Symbol) = ccall((:g_type_from_name, libgobject), GType, (Ptr{UInt8},), name)
const fundamental_ids = tuple(GType[g_type_from_name(name) for (name, c, j, f) in fundamental_types]...)

let jtypes = Expr(:block, :( g_type(::Type{Nothing}) = $(g_type_from_name(:void)) ))
    for i = 1:length(fundamental_types)
        (name, ctype, juliatype, g_value_fn) = fundamental_types[i]
        if juliatype != Union{}
            push!(jtypes.args, :( g_type(::Type{T}) where {T <: $juliatype} = convert(GType, $(fundamental_ids[i])) ))
        end
    end
    Core.eval(GLibBase, jtypes)
end

g_isa(gtyp::GType, is_a_type::GType) = ccall((:g_type_is_a, libgobject), Cint, (GType, GType), gtyp, is_a_type) != 0
g_type_name(g_type::GType) = Symbol(bytestring(ccall((:g_type_name, libgobject), Ptr{UInt8}, (GType,), g_type)))

g_type_test_flags(g_type::GType, flag) = ccall((:g_type_test_flags, libgobject), Bool, (GType, GEnum), g_type, flag)
const G_TYPE_FLAG_CLASSED           = 1 << 0
const G_TYPE_FLAG_INSTANTIATABLE    = 1 << 1
const G_TYPE_FLAG_DERIVABLE         = 1 << 2
const G_TYPE_FLAG_DEEP_DERIVABLE    = 1 << 3
mutable struct GObjectLeaf <: GObject
    handle::Ptr{GObject}
end
