# Gtk linked list

## Type hierarchy information

### an _LList is expected to have a data::Ptr{T} and next::Ptr{_LList{T}} element
### they are expected to be allocated and freed by GLib (e.g. with malloc/free)
abstract type _LList{T} end

struct _GSList{T} <: _LList{T}
    data::Ptr{T}
    next::Ptr{_GSList{T}}
end
struct _GList{T} <: _LList{T}
    data::Ptr{T}
    next::Ptr{_GList{T}}
    prev::Ptr{_GList{T}}
end

eltype(::Type{_LList{T}}) where {T} = T
eltype(::Type{L}) where {L <: _LList} = eltype(supertype(L))

mutable struct GList{L <: _LList, T} <: AbstractVector{T}
    handle::Ptr{L}
    transfer_full::Bool
    function GList{L,T}(handle, transfer_full::Bool) where {L<:_LList,T}
        # if transfer_full == true, then also free the elements when finalizing the list
        # this function assumes the caller will take care of holding a pointer to the returned object
        # until it wants to be garbage collected
        @assert T == eltype(L)
        l = new{L,T}(handle, transfer_full)
        finalizer(empty!, l)
        return l
    end
end
