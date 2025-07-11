abstract type GTypeInstance end
abstract type GObject <: GTypeInstance end
abstract type GInterface <: GObject end
abstract type GBoxed  end

const  GEnum = Int32
const  GType = Csize_t

abstract type GParam end
struct GParamSpec
  g_type_instance::Ptr{Nothing}
  name::Ptr{UInt8}
  flags::UInt32 # matches the type of the Enum from introspection
  value_type::GType
  owner_type::GType
end

function glib_ref(x::Ptr{GParamSpec})
    ccall((:g_param_spec_ref, libgobject), Nothing, (Ptr{GParamSpec},), x)
end
function glib_unref(x::Ptr{GParamSpec})
    ccall((:g_param_spec_unref, libgobject), Nothing, (Ptr{GParamSpec},), x)
end

"""
    GVariant(x)

Create a `GVariant` that contains the value `x`. This is a container used to
pass parameters and store states in GLib's action system.

The value is accessed from a `GVariant` `gv` using `gv[t]`, where `t` is the
Julia type. For example, to access a boolean inside a `GVariant`, use `gv[Bool]`.
"""
mutable struct GVariant
    handle::Ptr{GVariant}
    function GVariant(ref::Ptr{GVariant})
        x = new(ref)
    end
end

const fundamental_types = (
    #(:name,      Ctype,            JuliaType,      g_value_fn,     g_variant_fn)
    (:invalid,    Nothing,          Union{},        :error,         :error),
    (:void,       Nothing,          Nothing,        :error,         :error),
    (:GInterface, Ptr{Nothing},     GInterface,     :error,         :error),
    (:gchar,      Int8,             Int8,           :schar,         :error),
    (:guchar,     UInt8,            UInt8,          :uchar,         :byte),
    (:gboolean,   Cint,             Bool,           :boolean,       :boolean),
    (:gshort,     Cshort,           Int16,          :error,         :int16),
    (:gushort,    Cushort,          UInt16,         :error,         :uint16),
    (:gint,       Cint,             Int32,          :int,           :int32),
    (:guint,      Cuint,            UInt32,         :uint,          :uint32),
    (:glong,      Clong,            Union{},        :long,          :error),
    (:gulong,     Culong,           Union{},        :ulong,         :error),
    (:gint64,     Int64,            Signed,         :int64,         :int64),
    (:guint64,    UInt64,           Unsigned,       :uint64,        :uint64),
    (:GEnum,      GEnum,            Union{},        :enum,          :error),
    (:GFlags,     GEnum,            Union{},        :flags,         :error),
    (:gfloat,     Float32,          Float32,        :float,         :error),
    (:gdouble,    Float64,          AbstractFloat,  :double,        :double),
    (:gchararray, Ptr{UInt8},       AbstractString, :string,        :string),
    (:gpointer,   Ptr{Nothing},     Ptr,            :pointer,       :error),
    (:GBoxed,     Ptr{GBoxed},      GBoxed,         :boxed,         :error),
    (:GParam,     Ptr{GParamSpec},  Ptr{GParamSpec},:param,         :error),
    (:GObject,    Ptr{GObject},     GObject,        :object,        :error),
    (:GVariant,   Ptr{GVariant},    GVariant,       :variant,       :variant),
    )
# NOTE: in general do not cache ids, except for these fundamental values
g_type_from_name(name::Symbol) = ccall((:g_type_from_name, libgobject), GType, (Ptr{UInt8},), name)
const fundamental_ids = tuple(GType[g_type_from_name(name) for (name, c, j, f, v) in fundamental_types]...)

function get_gtype_decl(name::Symbol, lib, callname::Symbol)
    :(GLib.g_type(::Type{T}) where T <: $(esc(name)) =
        ccall(($(String(callname)), $(esc(lib))), GType, ()))
end

function get_interface_decl(iname::Symbol)
    quote
        struct $(esc(iname)) <: GInterface
            handle::Ptr{GObject}
            gc::Any
            $(esc(iname))(x::GObject) = new(unsafe_convert(Ptr{GObject}, x), x)
        end
    end
end

macro Giface(iname, lib, callname)
    gtype_decl = get_gtype_decl(iname, lib, callname)
    interf_decl = get_interface_decl(iname)
    ex=quote
        $(interf_decl)
        $(gtype_decl)
    end
    Base.remove_linenums!(ex)
end

"""
    g_type(x)

Get the GType corresponding to a Julia type or object. See
[GLib documentation](https://docs.gtk.org/gobject/concepts.html) for more
information.
"""
g_type(gtyp::GType) = gtyp
let jtypes = Expr(:block, :( g_type(::Type{Nothing}) = $(g_type_from_name(:void)) ))
    for i = 1:length(fundamental_types)
        (name, ctype, juliatype, g_value_fn, g_variant_fn) = fundamental_types[i]
        if juliatype != Union{}
            push!(jtypes.args, :( g_type(::Type{T}) where {T <: $juliatype} = convert(GType, $(fundamental_ids[i])) ))
        end
    end
    Core.eval(GLib, jtypes)
end

G_TYPE_FROM_CLASS(w::Ptr{Nothing}) = unsafe_load(convert(Ptr{GType}, w))
G_OBJECT_GET_CLASS(w::T) where T <: GObject = G_OBJECT_GET_CLASS(getfield(w,:handle))
function G_OBJECT_GET_CLASS(hnd::Ptr{T}) where T <: GObject
    hnd = check_undefref(hnd)
    unsafe_load(convert(Ptr{Ptr{Nothing}}, hnd))
end
G_OBJECT_CLASS_TYPE(w) = G_TYPE_FROM_CLASS(G_OBJECT_GET_CLASS(w))

g_isa(gtyp::GType, is_a_type::GType) = ccall((:g_type_is_a, libgobject), Cint, (GType, GType), gtyp, is_a_type) != 0
g_isa(gtyp, is_a_type) = g_isa(g_type(gtyp), g_type(is_a_type))
g_type_parent(child::GType) = ccall((:g_type_parent, libgobject), GType, (GType,), child)
g_type_name(g_type::GType) = Symbol(bytestring(ccall((:g_type_name, libgobject), Ptr{UInt8}, (GType,), g_type)))

mutable struct GObjectLeaf <: GObject
    handle::Ptr{GObject}
    function GObjectLeaf(handle::Ptr{GObject},owns=false)
        if handle == C_NULL
            error("Cannot construct $gname with a NULL pointer")
        end
        gobject_maybe_sink(handle, owns)
        return gobject_ref(new(handle))
    end
end

gtypes(types...) = GType[g_type(t) for t in types]

# caches holding various kinds of GTypes
const gtype_wrappers = Dict{Symbol, Type}()

quark_from_string(q) = ccall((:g_quark_from_string, libglib), UInt32, (Ptr{UInt8},), q)
macro quark_str(q)
    :( quark_from_string(bytestring($q)) )
end

unsafe_convert(::Type{Ptr{T}}, box::T) where {T <: GBoxed} = convert(Ptr{T}, box.handle)
convert(::Type{T}, boxed::GBoxed) where {T <: GBoxed} = convert(T, boxed.handle)
#convert(::Type{T}, unbox::Ptr{GBoxed}) where {T <: GBoxed} = convert(T, convert(Ptr{T}, unbox))
convert(::Type{T}, unbox::Ptr{T}, owns=false) where {T <: GBoxed} = T(unbox, owns)
convert(::Type{T}, unbox::Ptr{GBoxed}, owns=false) where {T <: GBoxed} = T(unbox, owns)

function delboxed(x::GBoxed)
    T=typeof(x)
    gtype = g_type(T)
    @debug begin
        name = g_type_name(gtype)
        "g_boxed_free($(x.handle)::$name)"
    end
    ccall((:g_boxed_free, libgobject), Nothing, (GType, Ptr{GBoxed},), gtype, x.handle)
end

function glib_ref(x::GBoxed)
    T=typeof(x)
    gtype = g_type(T)
    ccall((:g_boxed_copy, libgobject), Ptr{GBoxed}, (GType, Ptr{GBoxed},), gtype, x.handle)
end

cconvert(::Type{Ptr{GObject}}, @nospecialize(x::GObject)) = x

# All GObjects are expected to have a 'handle' field
# of type Ptr{GObject} corresponding to the GLib object
# or to override this method (e.g. GtkNullContainer, AbstractString)
unsafe_convert(::Type{Ptr{GObject}}, w::GObject) = getfield(w, :handle)

# This method should be used by gtk methods returning widgets of unknown type and/or that
# might have been wrapped by julia before, instead of a direct call to the constructor.
# The argument `owns` should be set to true when the method that produced the Ptr{GObject}
# transfers ownership to the callee.
convert(::Type{T}, w::Ptr{Y}, owns=false) where {T <: GObject, Y <: GObject} = convert_(T, convert(Ptr{T}, w), owns)
convert(::Type{T}, ptr::Ptr{T}, owns=false) where T <: GObject = convert_(T, ptr, owns)

# need to introduce convert_ since otherwise there was a StackOverFlow error
function convert_(::Type{T}, ptr::Ptr{T}, owns=false) where T <: GObject
    hnd = convert(Ptr{GObject}, ptr)
    if hnd == C_NULL
        throw(UndefRefError())
    end
    # look for an existing wrapper we can re-use
    x = ccall((:g_object_get_qdata, libgobject), Ptr{GObject}, (Ptr{GObject}, UInt32), hnd, jlref_quark::UInt32)
    if x != C_NULL
        ret = gobject_ref(unsafe_pointer_to_objref(x)::T)
        if owns # we already had a reference so we should get rid of the one we just received
            gc_unref(hnd)
        end
    else # new GObject, create a wrapper
        ret = wrap_gobject(hnd,owns)::T
    end
    ret
end

"""
    find_leaf_type(hnd::Ptr{T}) where T <: GObject

For a pointer to a `GObject`, look up its type in the `GType` system and return
the Julia leaf type that best matches it. For types supported by Gtk4, for
example `GtkWindow`, this will be the leaf type `GtkWindowLeaf`. Some types
defined in GTK4 and other libraries are not exported. In this case, the nearest
parent type supported by the Julia package will be returned. For example,
objects in GIO that implement the GFile interface are returned as
`GObjectLeaf`.
"""
function find_leaf_type(hnd::Ptr{T}) where T <: GObject
    gtyp = G_OBJECT_CLASS_TYPE(hnd)
    typname = g_type_name(gtyp)
    while !(typname in keys(gtype_wrappers))
        gtyp = g_type_parent(gtyp)
        @assert gtyp != 0
        typname = g_type_name(gtyp)
    end
    gtype_wrappers[typname]
end

# Finds the best leaf type and calls the constructor
function wrap_gobject(hnd::Ptr{GObject},owns=false)
    T = find_leaf_type(hnd)
    return T(hnd,owns) # these are defined in xlib_structs
end

### GList support for GObject
eltype(::Type{_LList{T}}) where {T <: GObject} = T
ref_to(::Type{T}, x) where {T <: GObject} = gobject_ref(unsafe_convert(Ptr{GObject}, x))
deref_to(::Type{T}, x::Ptr) where {T <: GObject} = convert(T, x)
#empty!(li::Ptr{_LList{Ptr{T}}}) where {T <: GObject} = gc_unref(unsafe_load(li).data)

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

"""
    glib_ref(x::Ptr)

Increments the reference count of a pointer managed by a GLib based library. Generally this function will just call a C function, e.g. `g_object_ref`. Most users will not ever need to use this function.
"""
function glib_ref(x::Ptr{GObject})
    ccall((:g_object_ref, libgobject), Nothing, (Ptr{GObject},), x)
end
function glib_ref(x::GObject)
    glib_ref(x.handle)
    x
end
glib_ref(::Nothing) = nothing
gc_unref(p::Ptr{GObject}) = glib_unref(p)

"""
    glib_unref(x::Ptr)

Decrements the reference count of a pointer managed by a GLib based library. Generally this function will just call a C function, e.g. `g_object_unref`. Most users will not ever need to use this function.
"""
function glib_unref(x::Ptr{GObject})
    ccall((:g_object_unref, libgobject), Nothing, (Ptr{GObject},), x)
end
function glib_ref_sink(x::Ptr{GObject})
    ccall((:g_object_ref_sink, libgobject), Nothing, (Ptr{GObject},), x)
end
const gc_preserve_glib = Dict{Union{WeakRef, GObject}, Bool}() # glib objects
const gc_preserve_glib_lock = Ref(false) # to satisfy this lock, must never decrement a ref counter while it is held
const await_lock = ReentrantLock()
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
        @lock await_lock push!(await_finalize, x)
        return # avoid running finalizers at random times
    end
    finalize_gc_unref(x)
    nothing
end
function addref(@nospecialize(x::GObject))
    # internal helper function
    finalizer(delref, x)
    if !haskey(gc_preserve_glib, x)
        gc_preserve_glib[WeakRef(x)] = false # record the existence of the object, but allow the finalizer
    end
    nothing
end
function gobject_maybe_sink(handle,owns::Bool)
    is_floating = (ccall(("g_object_is_floating", libgobject), Cint, (Ptr{GObject},), handle)!=0)
    if !owns || is_floating # if owns is true then we already have a reference, but if it's floating we should sink it
        glib_ref_sink(handle)
    end
end
function gobject_ref(x::T) where T <: GObject
    gc_preserve_glib_lock[] = true
    strong = get(gc_preserve_glib, x, nothing)
    if strong === nothing
        if ccall((:g_object_get_qdata, libgobject), Ptr{Cvoid},
                 (Ptr{GObject}, UInt32), x, jlref_quark::UInt32) != C_NULL
            # have set up metadata for this before, but its weakref has been cleared. restore the ref.
            @lock await_lock delete!(await_finalize, x)
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
        glib_ref(getfield(x,:handle))
        addref(Ref{GObject}(x)[])
    else
        # already gc-protected, nothing to do
    end
    gc_preserve_glib_lock[] = false
    # run_delayed_finalizers() # Commenting out helps with issue #99, unsure why
    return x
end
gc_ref(x::GObject) = pointer_from_objref(gobject_ref(x))

function run_delayed_finalizers()
    exiting[] && return # unnecessary to cleanup if we are about to die anyways
    g_yielded[] && return # can't run them right now
    topfinalizer[] = false
    if !isempty(await_finalize) # only do this once when we're doing GC stuff
        # prevents empty WeakRefs from filling gc_preserve_glib
        gc_preserve_glib_lock[] = true
        filter!(x->!(isa(x.first,WeakRef) && x.first.value === nothing),gc_preserve_glib)
        gc_preserve_glib_lock[] = false
    end
    @lock await_lock begin
        while !isempty(await_finalize)
            x = pop!(await_finalize)
            finalize_gc_unref(x)
        end
    end
    topfinalizer[] = true
end

function gc_unref_weak(x::GObject)
    # this strongly destroys and invalidates the object
    # it is intended to be called by GLib, not in user code function
    # note: this may be called multiple times by GLib
    setfield!(x,:handle, Ptr{GObject}(C_NULL))
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
        deref = @cfunction(gc_unref_weak, Nothing, (Ref{GObject},))
        ccall((:g_object_weak_ref, libgobject), Nothing, (Ptr{GObject}, Ptr{Nothing}, Any), x, deref, x)
    else
        ccall((:g_object_steal_qdata, libgobject), Any, (Ptr{GObject}, UInt32), x, jlref_quark::UInt32)
        gc_unref_weak(x)
    end
    nothing
end

gc_unref(::Ptr{GObject}, x::GObject) = gc_unref(x)
gc_ref_closure(x::GObject) = (gc_ref(x), C_NULL)

function gobject_move_ref(new::GObject, old::GObject)
    h = unsafe_convert(Ptr{GObject}, new)
    @assert h == unsafe_convert(Ptr{GObject}, old) != C_NULL
    glib_ref(h)
    gc_unref(old)
    gc_ref(new)
    # replace weak with strong reference
    gc_preserve_glib_lock[] = true
    filter!(x->!(isa(x.first,WeakRef) && x.first.value == new), gc_preserve_glib)
    gc_preserve_glib[new] = true
    gc_preserve_glib_lock[] = false
    glib_unref(h)
    new
end
