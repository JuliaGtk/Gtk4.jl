struct GError
    domain::UInt32
    code::Cint
    message::Ptr{UInt8}
end

message(err::GError) = bytestring(err.message)

#@make_gvalue(GError, Ptr{GError}, :boxed, (:g_error, :libgobject))
convert(::Type{GError}, err::Ptr{GError}) = GError(err)
g_type(::Type{GError}) = ccall((:g_error_get_type, libgobject), GType, ())

GError(err::Ptr{GError}) = unsafe_load(err)

function err_buf()
    err = Ref(Ptr{GError}());
    err[] = Ptr{GError}(C_NULL)
    err
end

struct GErrorException <: Exception
    domain::UInt32
    code::Cint
    message::String
end

GErrorException(err::GError) = GErrorException(err.domain, err.code, message(err))

function check_err(err::Base.RefValue{Ptr{GError}})
    if err[] != C_NULL
        gerror = GError(err[])
        ee = GErrorException(gerror)
        ccall((:g_clear_error,libglib),Nothing,(Ptr{Ptr{GError}},),err)
        throw(ee)
    end
end
