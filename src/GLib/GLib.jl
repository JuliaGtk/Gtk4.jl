module GLib

if isdefined(Base, :Experimental) && isdefined(Base.Experimental, Symbol("@optlevel"))
    @eval Base.Experimental.@optlevel 1
end

import Base: convert, copy, run, show, size, length, getindex, setindex!, get,
             iterate, eltype, isempty, popfirst!,
             empty!, append!, reverse!, pushfirst!, pop!, push!, splice!, insert!, deleteat!, delete!,
             unsafe_convert,
             getproperty, setproperty!, propertynames, getindex, setindex!, print, replace
import CEnum: @cenum, CEnum
import BitFlags: @bitflag, BitFlag

using Glib_jll
using Libdl, Preferences

export Maybe

export GList, GSList, glist_iter, _GSList, _GList, GError, GVariant, GType, GBoxed
export GObject, GInitiallyUnowned, GInterface, GTypeInterface, _GTypeInterface, GParam, GTypeInstance
export GByteArray, GHashTable, GPtrArray
export g_timeout_add, g_idle_add, @idle_add, @guarded, g_source_remove, cancel
export cfunction_, on_notify, signalnames, signal_return_type, signal_argument_types
export gobject_ref, signal_connect, signal_emit, signal_handler_disconnect
export signal_handler_block, signal_handler_unblock
export add_action, add_stateful_action

export get_gtk_property, set_gtk_property!, gtk_propertynames, bind_property, unbind_property
export bytestring, nothing_to_null, setproperties!, string_or_nothing, convert_if_not_null
export length_zt, err_buf, check_err, GErrorException
export gtkdoc_const_url, gtkdoc_enum_url, gtkdoc_flags_url, gtkdoc_method_url,
       gtkdoc_func_url, gtkdoc_struc_url

export gtype_wrappers, GVariantDict, GBytes, GVariantType
export GValue, GParamSpec, GTypeModule, _GValue, GValueLike

Maybe(T) = Union{T,Nothing}

cfunction_(@nospecialize(f), r, a::Tuple) = cfunction_(f, r, Tuple{a...})

@generated function cfunction_(f, R::Type{rt}, A::Type{at}) where {rt, at<:Tuple}
    quote
        @cfunction($(Expr(:$,:f)), $rt, ($(at.parameters...),))
    end
end

# local function, handles Symbol and makes UTF8-strings easier
const AbstractStringLike = Union{AbstractString, Symbol}
bytestring(s) = String(s)
bytestring(s::Symbol) = s
function bytestring(s::Union{Cstring,Ptr{UInt8}}, own::Bool=false)
    str=unsafe_string(s)
    if own
        g_free(s)
    end
    str
end
function string_or_nothing(s,owns)
    (s == C_NULL) ? nothing : bytestring(s, owns)
end

function convert_if_not_null(t,o,owns)
    if o == C_NULL
        nothing
    else
        convert(t, o, owns)
    end
end

function find_leaf_type_if_not_null(o,owns)
    if o == C_NULL
        nothing
    else
        leaftype = find_leaf_type(o)
        convert(leaftype, o, owns)
    end
end

g_malloc(s::Integer) = ccall((:g_malloc, libglib), Ptr{Nothing}, (Csize_t,), s)
g_free(p::Ptr) = ccall((:g_free, libglib), Nothing, (Ptr{Nothing},), p)
g_free(p::Cstring) = ccall((:g_free, libglib), Nothing, (Cstring,), p)
g_strfreev(p) = ccall((:g_strfreev, libglib), Nothing, (Ptr{Ptr{Nothing}},), p)

gtkdoc_const_url(ns,name)="https://docs.gtk.org/$(ns)/const.$(name).html"
gtkdoc_enum_url(ns,name)="https://docs.gtk.org/$(ns)/enum.$(name).html"
gtkdoc_flags_url(ns,name)="https://docs.gtk.org/$(ns)/flags.$(name).html"
gtkdoc_struc_url(ns,name)="https://docs.gtk.org/$(ns)/struct.$(name).html"
gtkdoc_class_url(ns,class)="https://docs.gtk.org/$(ns)/class.$(class).html"
gtkdoc_method_url(ns,class,method)="https://docs.gtk.org/$(ns)/method.$(class).$(method).html"
gtkdoc_func_url(ns,func)="https://docs.gtk.org/$(ns)/func.$(func).html"

# related to array handling
function length_zt(arr::Ptr)
    arr==C_NULL && return 0
    i=1
    while unsafe_load(arr,i)!=C_NULL
        i+=1
    end
    i-1
end

nothing_to_null(x) = something(x, C_NULL)

function check_undefref(p::Ptr)
    if p == C_NULL
        throw(UndefRefError())
    end
    p
end

# accessor generation
isgetter(m) = length(m.sig.parameters)==2
issetter(m) = length(m.sig.parameters)==3

function _extract_instance_type(m)
    tv, decls, file, line = Base.arg_decl_parts(m)
    # type unfortunately has a namespace attached
    p=split(decls[2][2],".")
    length(p)==0 && error("Empty instance type in accessor generation for $m: maybe skip this one?")
    length(p)>3 && return nothing
    p
end

# for an instance method in `G_`, generate a getter method
function gen_getter(func,v,m)
    p=_extract_instance_type(m)
    isnothing(p) && return nothing
    t=Symbol(p[end]) # the type name
    return :($v(x::$t)=G_.$func(x))
end

# for an instance method in `G_`, generate a setter method
function gen_setter(func,v,m)
    p=_extract_instance_type(m)
    isnothing(p) && return nothing
    t=Symbol(p[end]) # the type name
    return :($v(x::$t,y)=G_.$func(x,y))
end

function Base.:(==)(b::T, i::Integer) where T<:BitFlag
    Integer(b) == i
end

function Base.:(==)(i::Integer, b::T) where T<:BitFlag
    Integer(b) == i
end

include("glist.jl")
include("gtype.jl")

include("../gen/glib_consts")

const lib_version = VersionNumber(
      MAJOR_VERSION,
      MINOR_VERSION,
      MICRO_VERSION)

include("gvalues.jl")

include("../gen/glib_structs")

include("gvariant.jl")
include("gerror.jl")
include("arrays.jl")
include("hashtable.jl")

include("signals.jl")

include("../gen/gobject_structs")
include("../gen/gio_structs")

module G_

using Glib_jll

using ..GLib
using ..GLib: BookmarkFileError, ChecksumType, ConvertError, DateDMY, DateMonth, DateWeekday, ErrorType, FileError, IOChannelError, IOError, IOStatus, KeyFileError, LogWriterOutput, MarkupError, NormalizeMode, NumberParserError, OnceStatus, OptionArg, OptionError, RegexError, SeekType, ShellError, SliceConfig, SpawnError, TestFileType, TestLogType, TestResult, ThreadError, TimeType, TokenType, TraverseType, UnicodeBreakType, UnicodeScript, UnicodeType, UnixPipeEnd, UriError, UserDirectory, VariantClass, VariantParseError, BusType, ConverterResult, CredentialsType, DBusError, DBusMessageByteOrder, DBusMessageHeaderField, DBusMessageType, DataStreamByteOrder, DataStreamNewlineType, DriveStartStopType, EmblemOrigin, FileAttributeStatus, FileAttributeType, FileMonitorEvent, FileType, FilesystemPreviewType, IOErrorEnum, IOModuleScopeFlags, MemoryMonitorWarningLevel, MountOperationResult, NetworkConnectivity, NotificationPriority, PasswordSave, PollableReturn, ResolverError, ResolverRecordType, ResourceError, SocketClientEvent, SocketFamily, SocketListenerEvent, SocketProtocol, SocketType, TlsAuthenticationMode, TlsCertificateRequestFlags, TlsChannelBindingError, TlsChannelBindingType, TlsDatabaseLookupFlags, TlsError, TlsInteractionResult, UnixSocketAddressType, ZlibCompressorFormat, AsciiType, FileSetContentsFlags, FileTest, FormatSizeFlags, HookFlagMask, IOCondition, IOFlags, KeyFileFlags, LogLevelFlags, MainContextFlags, MarkupCollectType, MarkupParseFlags, OptionFlags, RegexCompileFlags, RegexMatchFlags, SpawnFlags, TestSubprocessFlags, TraverseFlags, UriFlags, UriHideFlags, UriParamsFlags, BindingFlags, ConnectFlags, IOCondition, ParamFlags, SignalFlags, SignalMatchType, TypeFlags, TypeFundamentalFlags, AppInfoCreateFlags, ApplicationFlags, AskPasswordFlags, BusNameOwnerFlags, BusNameWatcherFlags, ConverterFlags, DBusCallFlags, DBusCapabilityFlags, DBusConnectionFlags, DBusInterfaceSkeletonFlags, DBusMessageFlags, DBusObjectManagerClientFlags, DBusPropertyInfoFlags, DBusProxyFlags, DBusSendMessageFlags, DBusServerFlags, DBusSignalFlags, DBusSubtreeFlags, DriveStartFlags, FileAttributeInfoFlags, FileCopyFlags, FileCreateFlags, FileMeasureFlags, FileMonitorFlags, FileQueryInfoFlags, IOStreamSpliceFlags, MountMountFlags, MountUnmountFlags, OutputStreamSpliceFlags, ResolverNameLookupFlags, ResourceFlags, ResourceLookupFlags, SettingsBindFlags, SocketMsgFlags, SubprocessFlags, TestDBusFlags, TlsCertificateFlags, TlsDatabaseVerifyFlags, TlsPasswordFlags

import Base: convert, copy, run

include("../gen/glib_methods")
include("../gen/glib_functions")
include("../gen/gobject_methods")
include("../gen/gobject_functions")
include("../gen/gio_methods")
include("../gen/gio_functions")

end

get_pointer(x::Ptr) = x
get_pointer(x::GObject) = x.handle
get_pointer(x::GVariant) = x.handle
get_pointer(::Nothing) = C_NULL

include("gobject.jl")
include("listmodel.jl")
include("loop.jl")
include("actions.jl")
include("gio.jl")

function set_default_log_handler(log_func)
    global func = @cfunction(GLogFunc, Nothing, (Cstring, Cuint, Cstring, Ref{Function}))
    ref, deref = gc_ref_closure(log_func)
    ccall((:g_log_set_default_handler, libglib), Ptr{Cvoid}, (Ptr{Cvoid},Ptr{Cvoid}), func, ref)
end

function set_log_handler(log_domain, log_levels, log_func)
    func = @cfunction(GLogFunc, Nothing, (Cstring, Cuint, Cstring, Ref{Function}))
    ref, deref = gc_ref_closure(log_func)
    ccall((:g_log_set_handler_full, libglib), Cuint, (Cstring, Cint, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}), log_domain, Cuint(log_levels), func, ref, deref)
end

function GLogWriterFunc(log_level, fields, n_fields, user_data)
    log_level = LogLevelFlags(log_level)
    fields = collect(unsafe_wrap(Vector{_GLogField}, fields, n_fields))
    f = user_data
    ret = f(log_level, fields)
    convert(UInt32, ret)
end

"""
    set_log_writer_func(log_func)

Sets a function that is used to handle messages. The function should be of the form
`log_func(log_level,fields)` and should return `true` if the message was handled and
otherwise `false.`

This function must be called only once per Julia session.
"""
function set_log_writer_func(log_func)
    func = @cfunction(GLogWriterFunc, Cuint, (Cuint, Ptr{_GLogField}, Csize_t, Ref{Function}))
    ref, deref = gc_ref_closure(log_func)
    ccall((:g_log_set_writer_func, libglib), Nothing, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}), func, ref, deref)
end

"""
    suppress_C_messages()

Sets the preference `"C_message_handling"` to "suppress_all", which intercepts all
messages from the C libraries and stores them in an internal buffer. This setting
will take effect the next time Julia is started.

The stored messages can be found in `GLib.C_message_buffer`.

See also [`show_C_messages`](@ref).
"""
function suppress_C_messages()
    @set_preferences!("C_message_handling" => "suppress_all")
    @info("Setting will take effect after restarting Julia.")
end

"""
    show_C_messages()

Sets the preference `"C_message_handling"` to "", which allows messages and warnings
from the C libraries to be displayed. This setting will take effect the next time
Julia is started.

See also [`suppress_C_messages`](@ref).
"""
function show_C_messages()
    @set_preferences!("C_message_handling" => "")
    @info("Setting will take effect after restarting Julia.")
end

C_message_buffer::Vector{Tuple{LogLevelFlags,String,String}} = Tuple{LogLevelFlags,String,String}[]

function suppress_func(log_level, fields)
    imessage = findfirst(f->bytestring(f.key)=="MESSAGE", fields)
    idomain = findfirst(f->bytestring(f.key)=="GLIB_DOMAIN", fields)
    if imessage !== nothing && idomain !== nothing
        push!(C_message_buffer, (log_level,bytestring(Ptr{UInt8}(fields[idomain].value)),bytestring(Ptr{UInt8}(fields[imessage].value))))
        return true
    else
        return false
    end
end

const exiting = Ref(false)
function __init__()
    # check that libglib is compatible with what the GI generated code expects
    vercheck = G_.check_version(MAJOR_VERSION,MINOR_VERSION,0)
    if vercheck !== nothing
        @warn "GLib version check failed: $vercheck"
    end
    d = @load_preference("C_message_handling", "")
    if d == "suppress_all"
        set_log_writer_func(suppress_func)
    end
    global JuliaClosureMarshal = @cfunction(GClosureMarshal, Nothing,
        (Ptr{Nothing}, Ptr{GValue}, Cuint, Ptr{GValue}, Ptr{Nothing}, Ptr{Nothing}))
    exiting[] = false
    atexit(() -> (exiting[] = true))
    __init__gtype__()
    __init__gmainloop__()
    nothing
end

end
