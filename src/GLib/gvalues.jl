struct GValue
    g_type::GType
    field2::UInt64
    field3::UInt64
    GValue() = new(0, 0, 0)
end
# This should be a subtype of GBoxed and the above struct should be renamed to _GValue to be consistent with other boxed types
const _GValue = GValue
Base.zero(::Type{GValue}) = GValue()
function gvalue(::Type{T}) where T
    v = Ref(GValue())
    settype!(v, T)
    v
end
function gvalue(x)
    T = typeof(x)
    v = gvalue(T)
    v[T] = x
    v
end
function gvalues(xs...)
    v = zeros(GValue, length(xs))
    for (i, x) in enumerate(xs)
        T = typeof(x)
        gv = Ref(v, i)
        settype!(gv, T)  # init type
        gv[T] = x # init value
    end
    finalizer((v) -> for i = 1:length(v)
            ccall((:g_value_unset, libgobject), Nothing, (Ptr{GValue},), pointer(v, i))
        end, v)
    v
end

function settype!(gv::Ref{GValue}, ::Type{T}) where T <: GBoxed
    if T == GBoxed
        error("Need GType to store GBoxed in GValue")
    end
    gtype = g_type(T)
    ccall((:g_value_init, libgobject), Nothing, (Ptr{GValue}, Csize_t), gv, gtype)
    gv
end

function settype!(gv::Ref{GValue}, ::Type{T}) where T <: CEnum.Cenum
    gtype = g_type(T)
    ccall((:g_value_init, libgobject), Nothing, (Ptr{GValue}, Csize_t), gv, gtype)
    gv
end

function setindex!(v::Base.Ref{GValue}, x, ::Type{T}) where T <: CEnum.Cenum
    ccall((:g_value_set_enum, libgobject), Nothing, (Ptr{GValue}, Cint), v, x)
end

function settype!(gv::Ref{GValue}, ::Type{T}) where T <: BitFlag
    gtype = g_type(T)
    ccall((:g_value_init, libgobject), Nothing, (Ptr{GValue}, Csize_t), gv, gtype)
    gv
end

function setindex!(v::Base.Ref{GValue}, x, ::Type{T}) where T <: BitFlag
    ccall((:g_value_set_flags, libgobject), Nothing, (Ptr{GValue}, Cint), v, Int32(x))
end

function setindex!(dest::Base.RefValue{GValue}, src::Ref{GValue})
    ccall((:g_value_transform, libgobject), Cint, (Ptr{GValue}, Ptr{GValue}), src, dest) != 0
    src
end

function setindex!(dest::Ptr{GValue}, src::Ref{GValue})
    ccall((:g_value_transform, libgobject), Cint, (Ptr{GValue}, Ptr{GValue}), src, dest) != 0
    src
end

getindex(gv::Ref{GValue}, i::Int, ::Type{T}) where {T} = getindex(Ref(gv, i), T)
getindex(gv::Ref{GValue}, i::Int) = getindex(Ref(gv, i))
getindex(v::Ref{GValue}, i::Int, ::Type{Nothing}) = nothing

let handled = Set()
global make_gvalue, getindex
function make_gvalue(pass_x, as_ctype, to_gtype, with_id, cm::Module)
    with_id === :error && return
    if isa(with_id, Tuple)
        with_id = with_id::Tuple{Symbol, Any}
        with_id = :(ccall($(Expr(:tuple, Meta.quot(Symbol(string(with_id[1], "_get_type"))), with_id[2])), GType, ()))
        # with_id is now a GType
    end
    if pass_x !== Union{} && !(pass_x in handled)
        Core.eval(cm, quote
            function settype!(v::Base.Ref{GValue}, ::Type{T}) where T <: $pass_x
                ccall((:g_value_init, GLib.libgobject), Nothing, (Ptr{GLib.GValue}, Csize_t), v, $with_id)
                v
            end
            function Base.setindex!(v::Base.Ref{GValue}, x, ::Type{T}) where T <: $pass_x
                $(  if to_gtype == :string
                        :(x = GLib.bytestring(x))
                    elseif to_gtype == :pointer || to_gtype == :boxed
                        :(x = Ref{$pass_x}(x))
                    elseif to_gtype == :gtype
                        :(x = GLib.g_type(x))
                    end)
                ccall(($(string("g_value_set_", to_gtype)), GLib.libgobject), Nothing, (Ptr{GLib.GValue}, $as_ctype), v, x)
                if isa(v, Base.RefValue)
                    finalizer((v::Base.RefValue) -> ccall((:g_value_unset, GLib.libgobject), Nothing, (Ptr{GLib.GValue},), v), v)
                end
                v
            end
        end)
    end
    if pass_x !== Union{} && !(pass_x in handled)
        push!(handled, pass_x)
        Core.eval(cm, quote
            function Base.getindex(v::Ref{GLib.GValue}, ::Type{T}) where T <: $pass_x
                x = ccall(($(string("g_value_get_", to_gtype)), GLib.libgobject), $as_ctype, (Ptr{GLib.GValue},), v)
                if x == C_NULL
                    return nothing
                end
                $(  if to_gtype == :string
                        :(x = GLib.bytestring(x))
                    elseif pass_x == Symbol
                        :(x = Symbol(x))
                    end)
                return Base.convert(T, x)
            end
        end)
    end
    return nothing
end
end #let

macro make_gvalue(pass_x, as_ctype, to_gtype, with_id, opt...)
    esc(:(make_gvalue($pass_x, $as_ctype, $to_gtype, $with_id, $__module__, $(opt...))))
end

function make_gvalue_from_fundamental_type(i,cm)
  (name, ctype, juliatype, g_value_fn, g_variant_fn) = fundamental_types[i]
  fundamental_ids[i] === :error && return
  if juliatype !== Union{} && g_value_fn != :error
      if juliatype !==GBoxed
          Core.eval(cm, quote
            function settype!(v::Base.Ref{GValue}, ::Type{T}) where T <: $juliatype
                ccall((:g_value_init, GLib.libgobject), Nothing, (Ptr{GLib.GValue}, Csize_t), v, $(fundamental_ids[i]))
                v
            end
        end)
      end
      Core.eval(cm, quote
          function Base.setindex!(v::Base.Ref{GValue}, x, ::Type{T}) where T <: $juliatype
              $(  if g_value_fn == :string
                      :(x = GLib.bytestring(x))
                  elseif g_value_fn == :pointer
                      :(x = Ref{$juliatype}(x))
                  elseif g_value_fn == :gtype
                      :(x = GLib.g_type(x))
                  end)
              ccall(($(string("g_value_set_", g_value_fn)), GLib.libgobject), Nothing, (Ptr{GLib.GValue}, $ctype), v, x)
              if isa(v, Base.RefValue)
                  finalizer((v::Base.RefValue) -> ccall((:g_value_unset, GLib.libgobject), Nothing, (Ptr{GLib.GValue},), v), v)
              end
              v
          end
      end)
  end
  if g_value_fn == :static_string
      g_value_fn = :string
  end
  if juliatype !== Union{} && g_value_fn !== :error
      Core.eval(cm, quote
          function Base.getindex(v::Ref{GValue}, ::Type{T}) where T <: $juliatype
              x = ccall(($(string("g_value_get_", g_value_fn)), GLib.libgobject), $ctype, (Ptr{GValue},), v)
              if x == C_NULL
                  return nothing
              end
              $(  if g_value_fn == :string
                      :(x = GLib.bytestring(x))
                  elseif juliatype == Symbol
                      :(x = Symbol(x))
                  end)
              return Base.convert(T, x)
          end
      end)
  end
  fn = Core.eval(cm, quote
    function(v::Base.Ref{GValue})
              x = ccall(($(string("g_value_get_", g_value_fn)), GLib.libgobject), $ctype, (Ptr{GValue},), v)
              $(if g_value_fn == :string; :(x = (x == C_NULL ? nothing : GLib.bytestring(x))) end)
              $(if juliatype == AbstractString
                  :(return x)
              elseif juliatype !== Union{}
                  :(return x == C_NULL ? nothing : Base.convert($juliatype, x))
              else
                  :(return x)
              end)
          end
      end)
  return fn
end

const gvalue_types = Any[]
const gboxed_types = Any[]
const fundamental_fns = tuple(Function[ make_gvalue_from_fundamental_type(i, @__MODULE__) for
                              i in 1:length(fundamental_types)]...)
@make_gvalue(Symbol, Ptr{UInt8}, :static_string, :(g_type(AbstractString)))
#@make_gvalue(Type, GType, :gtype, (:g_gtype, :libgobject))

g_type(::Type{GValue}) = ccall(("g_value_get_type", libgobject), GType, ())
push!(gboxed_types, GValue)
function getindex(v::Base.RefValue{GValue}, ::Type{GValue})
    x = ccall(("g_value_get_boxed", libgobject), Ptr{GValue}, (Ptr{GValue},), v)
    if x == C_NULL
        return nothing
    end
    x
end

function getindex(gv::Base.Ref{GValue}, ::Type{Any})
    gtyp = gv[].g_type
    if gtyp == 0
        error("Invalid GValue type")
    end
    if gtyp == g_type(Nothing)
        return nothing
    end
    if gtyp == g_type(GBoxed)
        error("GType of $gv is GBoxed, but we need the actual type.")
    end
    # first pass: fast loop for fundamental types
    for (i, id) in enumerate(fundamental_ids)
        if id == gtyp  # if g_type == id
            return fundamental_fns[i](gv)
        end
    end
    # second pass: GBoxed types
    for typ in gboxed_types
        if gtyp == g_type(typ)
            return getindex(gv,typ)
        end
    end
    # third pass: user defined (sub)types
    for (typ, typefn, getfn) in gvalue_types
        if g_isa(gtyp, typefn())
            return getfn(gv)
        end
    end
    # last pass: check for derived fundamental types (which have not been overridden by the user)
    for (i, id) in enumerate(fundamental_ids)
        if g_isa(gtyp, id)
            return fundamental_fns[i](gv)
        end
    end
    typename = g_type_name(gtyp)
    error("Could not convert GValue of type $typename to Julia type")
end
#end

get_gtk_property(w::GObject, name::AbstractString, ::Type{T}) where T = get_gtk_property(w, String(name)::String, T)
get_gtk_property(w::GObject, name::Symbol, ::Type{T}) where T = get_gtk_property(w, String(name), T)
function get_gtk_property(w::GObject, name::String, ::Type{T}) where T
    v = gvalue(T)
    ccall((:g_object_get_property, libgobject), Nothing,
        (Ptr{GObject}, Ptr{UInt8}, Ptr{GValue}), w, name, v)
    val = v[T]
    ccall((:g_value_unset, libgobject), Nothing, (Ptr{GValue},), v)
    if (isa(val, GBoxed) || isa(val, GObject) || isa(val, GInterface) || isa(val, GVariant)) && val.handle==C_NULL
        return nothing
    end
    return val
end
get_gtk_property(w::GObject, name::AbstractString) = get_gtk_property(w, String(name)::String)
get_gtk_property(w::GObject, name::Symbol) = get_gtk_property(w, String(name))
function get_gtk_property(w::GObject, name::String)
    v = Ref(GValue())
    ccall((:g_object_get_property, libgobject), Nothing,
        (Ptr{GObject}, Ptr{UInt8}, Ptr{GValue}), w, name, v)
    val = v[Any]
    ccall((:g_value_unset, libgobject), Nothing, (Ptr{GValue},), v)
    if (isa(val, GBoxed) || isa(val, GObject) || isa(val, GInterface) || isa(val, GVariant)) && val.handle==C_NULL
        return nothing
    end
    return val
end

set_gtk_property!(w::GObject, name, ::Type{T}, value) where T = set_gtk_property!(w, name, convert(T, value))
set_gtk_property!(w::GObject, name::AbstractString, value) = set_gtk_property!(w::GObject, String(name)::String, value)
set_gtk_property!(w::GObject, name::Symbol, value) = set_gtk_property!(w::GObject, String(name), value)
function set_gtk_property!(w::GObject, name::String, value)
    if value!==nothing
        gv=gvalue(value)
    else
        # need to get the type
        gv = Ref(GValue())
        ccall((:g_object_get_property, libgobject), Nothing,
            (Ptr{GObject}, Ptr{UInt8}, Ptr{GValue}), w, name, gv)
        ccall((:g_value_reset, libgobject), Nothing, (Ptr{GValue},), gv)
    end
    ccall((:g_object_set_property, libgobject), Nothing,
        (Ptr{GObject}, Ptr{UInt8}, Ptr{GValue}), w, name, gv)

    w
end

"""
    gtk_propertynames(w::GObject)

Prints a list of property names for the GObject `w`.
"""
function gtk_propertynames(w::GObject)
    n = Ref{Cuint}()
    props = ccall((:g_object_class_list_properties, libgobject), Ptr{Ptr{GParamSpec}},
        (Ptr{Nothing}, Ptr{Cuint}), G_OBJECT_GET_CLASS(w), n)
    names=Vector{Symbol}(undef,n[])
    for i = 1:n[]
        param = unsafe_load(unsafe_load(props, i))
        names[i]=Symbol(replace(bytestring(param.name),"-"=>"_"))
    end
    g_free(props)
    names
end

propertynames(w::GObject) = (gtk_propertynames(w)...,fieldnames(typeof(w))...)

function getproperty(w::GObject, name::Symbol)
    in(name, fieldnames(typeof(w))) && return getfield(w, name)
    get_gtk_property(w,name)
end

function setproperty!(w::GObject, name::Symbol, val)
    in(name, fieldnames(typeof(w))) && return setfield!(w, name, val)
    set_gtk_property!(w,name,val)
end
