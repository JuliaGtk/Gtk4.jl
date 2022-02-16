abstract type GObject end
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

g_type(gtyp::GType) = gtyp
let jtypes = Expr(:block, :( g_type(::Type{Nothing}) = $(g_type_from_name(:void)) ))
    for i = 1:length(fundamental_types)
        (name, ctype, juliatype, g_value_fn) = fundamental_types[i]
        if juliatype != Union{}
            push!(jtypes.args, :( g_type(::Type{T}) where {T <: $juliatype} = convert(GType, $(fundamental_ids[i])) ))
        end
    end
    Core.eval(GLib, jtypes)
end

G_TYPE_FROM_CLASS(w::Ptr{Nothing}) = unsafe_load(convert(Ptr{GType}, w))
G_OBJECT_GET_CLASS(w::GObject) = G_OBJECT_GET_CLASS(w.handle)
G_OBJECT_GET_CLASS(hnd::Ptr{GObject}) = unsafe_load(convert(Ptr{Ptr{Nothing}}, hnd))
G_OBJECT_CLASS_TYPE(w) = G_TYPE_FROM_CLASS(G_OBJECT_GET_CLASS(w))

g_isa(gtyp::GType, is_a_type::GType) = ccall((:g_type_is_a, libgobject), Cint, (GType, GType), gtyp, is_a_type) != 0
g_isa(gtyp, is_a_type) = g_isa(g_type(gtyp), g_type(is_a_type))
g_type_parent(child::GType) = ccall((:g_type_parent, libgobject), GType, (GType,), child)
g_type_name(g_type::GType) = Symbol(bytestring(ccall((:g_type_name, libgobject), Ptr{UInt8}, (GType,), g_type)))

g_type_test_flags(g_type::GType, flag) = ccall((:g_type_test_flags, libgobject), Bool, (GType, GEnum), g_type, flag)
const G_TYPE_FLAG_CLASSED           = 1 << 0
const G_TYPE_FLAG_INSTANTIATABLE    = 1 << 1
const G_TYPE_FLAG_DERIVABLE         = 1 << 2
const G_TYPE_FLAG_DEEP_DERIVABLE    = 1 << 3
mutable struct GObjectLeaf <: GObject
    handle::Ptr{GObject}
    function GObjectLeaf(handle::Ptr{GObject})
        if handle == C_NULL
            error("Cannot construct $gname with a NULL pointer")
        end
        return gobject_ref(new(handle))
    end
end

g_type(obj::GObject) = g_type(typeof(obj))

gtypes(types...) = GType[g_type(t) for t in types]

# caches holding various kinds of GTypes
const gtype_abstracts = Dict{Symbol, Type}()
const gtype_wrappers = Dict{Symbol, Type}()
const gtype_ifaces = Dict{Symbol, Type}()

gtype_abstracts[:GObject] = GObject
gtype_wrappers[:GObject] = GObjectLeaf

let libs = Dict{AbstractString, Any}()
global get_fn_ptr
function get_fn_ptr(fnname, lib, cm)
    if !isa(lib, AbstractString)
        lib = Core.eval(cm, lib)
    end
    libptr = get(libs, lib, C_NULL)::Ptr{Nothing}
    if libptr == C_NULL
        libs[lib] = libptr = dlopen(lib)
    end
    fnptr = dlsym_e(libptr, fnname)
end
end
function g_type(name::Symbol, lib, symname::Symbol, cm)
    if name in keys(gtype_wrappers)
        return g_type(gtype_wrappers[name])
    end
    fnptr = get_fn_ptr(string(symname, "_get_type"), lib, cm)
    if fnptr != C_NULL
        ccall(fnptr, GType, ())
    else
        convert(GType, 0)
    end
end
g_type(name::Symbol, lib, symname::Expr, cm) = Core.eval(cm, symname)
g_type(name::Expr, lib::Expr, symname::Expr, cm) = info( (name,lib,symname) )

macro quark_str(q)
    :( ccall((:g_quark_from_string, libglib), UInt32, (Ptr{UInt8},), bytestring($q)) )
end

unsafe_convert(::Type{Ptr{T}}, box::T) where {T <: GBoxed} = convert(Ptr{T}, box.handle)
convert(::Type{GBoxed}, boxed::GBoxed) = boxed
convert(::Type{T}, boxed::T) where {T <: GBoxed} = boxed
convert(::Type{T}, boxed::GBoxed) where {T <: GBoxed} = convert(T, boxed.handle)
convert(::Type{T}, unbox::Ptr{GBoxed}) where {T <: GBoxed} = convert(T, convert(Ptr{T}, unbox))
convert(::Type{T}, unbox::Ptr{T}) where {T <: GBoxed} = T(unbox)

cconvert(::Type{Ptr{GObject}}, @nospecialize(x::GObject)) = x

# All GObjects are expected to have a 'handle' field
# of type Ptr{GObject} corresponding to the GLib object
# or to override this method (e.g. GtkNullContainer, AbstractString)
unsafe_convert(::Type{Ptr{GObject}}, w::GObject) = getfield(w, :handle)

# this method should be used by gtk methods returning widgets of unknown type
# and/or that might have been wrapped by julia before,
# instead of a direct call to the constructor
convert(::Type{T}, w::Ptr{GObject}, steal=false) where {T <: GObject} = convert_(T, convert(Ptr{T}, w), steal) # this definition must be first due to a 0.2 dispatch bug
convert(::Type{T}, ptr::Ptr{T}, steal=false) where T <: GObject = convert_(T, ptr, steal)

# need to introduce convert_ since otherwise there was a StackOverFlow error
function convert_(::Type{T}, ptr::Ptr{T}, steal=false) where T <: GObject
    hnd = convert(Ptr{GObject}, ptr)
    if hnd == C_NULL
        throw(UndefRefError())
    end
    # look for an existing wrapper we can re-use
    x = ccall((:g_object_get_qdata, libgobject), Ptr{GObject}, (Ptr{GObject}, UInt32), hnd, jlref_quark::UInt32)
    if x != C_NULL
        ret = gobject_ref(unsafe_pointer_to_objref(x)::T)
        if steal
            gc_unref(hnd)
        end
    else
        # create a wrapper
        ret = wrap_gobject(hnd)::T
        is_floating = (ccall(("g_object_is_floating", libgobject), Cint, (Ptr{GObject},), hnd)!=0)
        if !steal || is_floating
            gc_ref_sink(hnd)
        end
    end
    ret
end

function wrap_gobject(hnd::Ptr{GObject})
    gtyp = G_OBJECT_CLASS_TYPE(hnd)
    typname = g_type_name(gtyp)
    while !(typname in keys(gtype_wrappers))
        gtyp = g_type_parent(gtyp)
        @assert gtyp != 0
        typname = g_type_name(gtyp)
    end

    T = gtype_wrappers[typname]
    return T(hnd)
end

eltype(::Type{_LList{T}}) where {T <: GObject} = T
ref_to(::Type{T}, x) where {T <: GObject} = gobject_ref(unsafe_convert(Ptr{GObject}, x))
deref_to(::Type{T}, x::Ptr) where {T <: GObject} = convert(T, x)
empty!(li::Ptr{_LList{Ptr{T}}}) where {T <: GObject} = gc_unref(unsafe_load(li).data)

### Miscellaneous types
baremodule GConnectFlags
    const AFTER = 1
    const SWAPPED = 2
    get(s::Symbol) =
        if s === :after
            AFTER
        elseif s === :swapped
            SWAPPED
        else
            Main.Base.error(Main.Base.string("invalid GConnectFlag ", s))
        end
end

### Garbage collection [prevention]
const gc_preserve = IdDict{Any, Any}() # reference counted closures
function gc_ref(@nospecialize(x))
    global gc_preserve
    local ref::Ref{Any}, cnt::Int
    if x in keys(gc_preserve)
        ref, cnt = gc_preserve[x]::Tuple{Ref{Any}, Int}
    else
        ref = Ref{Any}(x)
        cnt = 0
    end
    gc_preserve[x] = (ref, cnt + 1)
    return unsafe_load(convert(Ptr{Ptr{Nothing}}, unsafe_convert(Ptr{Any}, ref)))
end
function gc_unref(@nospecialize(x))
    global gc_preserve
    ref, cnt = gc_preserve[x]::Tuple{Ref{Any}, Int}
    @assert cnt > 0
    if cnt == 1
        delete!(gc_preserve, x)
    else
        gc_preserve[x] = (ref, cnt - 1)
    end
    nothing
end
_gc_unref(@nospecialize(x), ::Ptr{Nothing}) = gc_unref(x)
gc_ref_closure(@nospecialize(cb::Function)) = (invoke(gc_ref, Tuple{Any}, cb), @cfunction(_gc_unref, Nothing, (Any, Ptr{Nothing})))
gc_ref_closure(x::T) where {T} = (gc_ref(x), @cfunction(_gc_unref, Nothing, (Any, Ptr{Nothing})))

# generally, you shouldn't be calling gc_ref(::Ptr{GObject})
function gc_ref(x::Ptr{GObject})
    ccall((:g_object_ref, libgobject), Nothing, (Ptr{GObject},), x)
end
function gc_ref_sink(x::Ptr{GObject})
    ccall((:g_object_ref_sink, libgobject), Nothing, (Ptr{GObject},), x)
end
function gc_unref(x::Ptr{GObject})
    ccall((:g_object_unref, libgobject), Nothing, (Ptr{GObject},), x)
end

const gc_preserve_glib = Dict{Union{WeakRef, GObject}, Bool}() # glib objects
const gc_preserve_glib_lock = Ref(false) # to satisfy this lock, must never decrement a ref counter while it is held
const topfinalizer = Ref(true) # keep recursion to a minimum by only iterating from the top
const await_finalize = Set{Any}()

Base.isequal(x::GObject, w::WeakRef) = x === w.value   # cuts the number of MethodInstances from O(N^2) to O(N)

function finalize_gc_unref(@nospecialize(x::GObject))
    # this records that the are no user references left to the object from Julia
    # and notifies GLib that it can free the object (if no reference exist from C)
    # it is intended to be called by GC, not in user code function
    istop = topfinalizer[]
    topfinalizer[] = false
    gc_preserve_glib_lock[] = true
    delete!(gc_preserve_glib, x)
    if getfield(x, :handle) != C_NULL
        gc_preserve_glib[x] = true # convert to a strong-reference
        gc_preserve_glib_lock[] = false
        gc_unref(unsafe_convert(Ptr{GObject}, x)) # may clear the strong reference
    else
        gc_preserve_glib_lock[] = false
    end
    topfinalizer[] = istop
    istop && run_delayed_finalizers()
    nothing
end

function delref(@nospecialize(x::GObject))
    # internal helper function
    exiting[] && return # unnecessary to cleanup if we are about to die anyways
    if gc_preserve_glib_lock[] || g_yielded[]
        push!(await_finalize, x)
        return # avoid running finalizers at random times
    end
    finalize_gc_unref(x)
    nothing
end
function addref(@nospecialize(x::GObject))
    # internal helper function
    finalizer(delref, x)
    delete!(gc_preserve_glib, x) # in v0.2, the WeakRef assignment below wouldn't update the key
    gc_preserve_glib[WeakRef(x)] = false # record the existence of the object, but allow the finalizer
    nothing
end
function gobject_ref(x::T) where T <: GObject
    gc_preserve_glib_lock[] = true
    strong = get(gc_preserve_glib, x, nothing)
    if strong === nothing
        if ccall((:g_object_get_qdata, libgobject), Ptr{Cvoid},
                 (Ptr{GObject}, UInt32), x, jlref_quark::UInt32) != C_NULL
            # have set up metadata for this before, but its weakref has been cleared. restore the ref.
            delete!(await_finalize, x)
            finalizer(delref, x)
            gc_preserve_glib[WeakRef(x)] = false # record the existence of the object, but allow the finalizer
        else
            # we haven't seen this before, setup the metadata
            deref = @cfunction(gc_unref, Nothing, (Ref{T},))
            ccall((:g_object_set_qdata_full, libgobject), Nothing,
                  (Ptr{GObject}, UInt32, Any, Ptr{Nothing}), x, jlref_quark::UInt32, x,
                  deref) # add a circular reference to the Julia object in the GObject
            addref(Ref{GObject}(x)[])
        end
    elseif strong
        # oops, we previously deleted the link, but now it's back
        addref(Ref{GObject}(x)[])
    else
        # already gc-protected, nothing to do
    end
    gc_preserve_glib_lock[] = false
    run_delayed_finalizers()
    return x
end
gc_ref(x::GObject) = pointer_from_objref(gobject_ref(x))

function run_delayed_finalizers()
    exiting[] && return # unnecessary to cleanup if we are about to die anyways
    g_yielded[] && return # can't run them right now
    topfinalizer[] = false
    while !isempty(await_finalize)
        x = pop!(await_finalize)
        finalize_gc_unref(x)
    end
    topfinalizer[] = true
end

function gc_unref_weak(x::GObject)
    # this strongly destroys and invalidates the object
    # it is intended to be called by GLib, not in user code function
    # note: this may be called multiple times by GLib
    x.handle = C_NULL
    gc_preserve_glib_lock[] = true
    delete!(gc_preserve_glib, x)
    gc_preserve_glib_lock[] = false
    nothing
end

function gc_unref(x::GObject)
    # this strongly destroys and invalidates the object
    # it is intended to be called by GLib, not in user code function
    ref = ccall((:g_object_get_qdata, libgobject), Ptr{Nothing}, (Ptr{GObject}, UInt32), x, jlref_quark::UInt32)
    if ref != C_NULL && x !== unsafe_pointer_to_objref(ref)
        # We got called because we are no longer the default object for this handle, but we are still alive
        @warn("Duplicate Julia object creation detected for GObject")
        deref = cfunction_(gc_unref_weak, Nothing, (Ref{typeof(x)},))
        ccall((:g_object_weak_ref, libgobject), Nothing, (Ptr{GObject}, Ptr{Nothing}, Any), x, deref, x)
    else
        ccall((:g_object_steal_qdata, libgobject), Any, (Ptr{GObject}, UInt32), x, jlref_quark::UInt32)
        gc_unref_weak(x)
    end
    nothing
end

gc_unref(::Ptr{GObject}, x::GObject) = gc_unref(x)
gc_ref_closure(x::GObject) = (gc_ref(x), C_NULL)

function gc_force_floating(x::GObject)
    ccall((:g_object_force_floating, libgobject), Nothing, (Ptr{GObject},), x)
end
function gobject_move_ref(new::GObject, old::GObject)
    h = unsafe_convert(Ptr{GObject}, new)
    @assert h == unsafe_convert(Ptr{GObject}, old) != C_NULL
    gc_ref(h)
    gc_unref(old)
    gc_ref(new)
    gc_unref(h)
    new
end

function delboxed(x::GBoxed)
    T=typeof(x)
    gtype = g_type(T)
    ccall((:g_boxed_free, libgobject), Nothing, (GType, Ptr{GBoxed},), gtype, x.handle)
end
