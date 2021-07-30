# Attributes

export Attribute
"""
    struct Attribute

Holds a C pointer `adios2_attribute *`.
"""
struct Attribute
    ptr::Ptr{Cvoid}
    adios::Adios
    Attribute(ptr::Ptr{Cvoid}, adios::Adios) = new(ptr, adios)
end

function Base.show(io::IO, ::MIME"text/plain", attribute::Attribute)
    nm = name(attribute)
    return print(io, "Attribute{$nm}")
end

export name
"""
    attr_name = name(attribute::Attribute)
    attr_name::Union{Nothing,String}

Retrieve attribute name.
"""
function name(attribute::Attribute)
    size = Ref{Csize_t}()
    err = ccall((:adios2_attribute_name, libadios2_c), Cint,
                (Ptr{Cchar}, Ref{Csize_t}, Ptr{Cvoid}), C_NULL, size,
                attribute.ptr)
    Error(err) ≠ error_none && return nothing
    name = Array{Cchar}(undef, size[])
    err = ccall((:adios2_attribute_name, libadios2_c), Cint,
                (Ptr{Cchar}, Ref{Csize_t}, Ptr{Cvoid}), name, size,
                attribute.ptr)
    Error(err) ≠ error_none && return nothing
    return unsafe_string(pointer(name), size[])
end

export type
"""
    attr_type = type(attribute::Attribute)
    attr_type::Union{Nothing,Type}

Retrieve attribute type.
"""
function type(attribute::Attribute)
    type = Ref{Cint}()
    err = ccall((:adios2_attribute_type, libadios2_c), Cint,
                (Ref{Cint}, Ptr{Cvoid}), type, attribute.ptr)
    Error(err) ≠ error_none && return nothing
    return julia_type(AType(type[]))
end

export is_value
"""
    attr_is_value = is_value(attribute::Attribute)
    attr_is_value::Union{Nothing,Bool}

Retrieve attribute type.
"""
function is_value(attribute::Attribute)
    is_value = Ref{Cint}()
    err = ccall((:adios2_attribute_is_value, libadios2_c), Cint,
                (Ref{Cint}, Ptr{Cvoid}), is_value, attribute.ptr)
    Error(err) ≠ error_none && return nothing
    return Bool(is_value[])
end

"""
    attr_size = size(attribute::Attribute)
    attr_size::Union{Nothing,Int}

Retrieve attribute size.
"""
function Base.size(attribute::Attribute)
    size = Ref{Csize_t}()
    err = ccall((:adios2_attribute_size, libadios2_c), Cint,
                (Ref{Csize_t}, Ptr{Cvoid}), size, attribute.ptr)
    Error(err) ≠ error_none && return nothing
    return Int(size[])
end

export data
"""
    attr_data = data(attribute::Attribute)
    attr_data::Union{Nothing,AdiosType,Vector{<:AdiosType}}

Retrieve attribute Data.
"""
function data(attribute::Attribute)
    T = type(attribute)
    T ≡ nothing && return nothing
    @assert T != Union{}
    isval = is_value(attribute)
    isval ≡ nothing && return nothing
    sz = size(attribute)
    sz ≡ nothing && return nothing
    tp = type(attribute)
    tp ≡ nothing && return nothing
    if tp ≡ String
        if isval
            buffer = fill(Cchar(0), string_array_element_max_size)
            out_sz = Ref{Csize_t}()
            err = ccall((:adios2_attribute_data, libadios2_c), Cint,
                        (Ptr{Cchar}, Ref{Csize_t}, Ptr{Cvoid}), buffer, out_sz,
                        attribute.ptr)
            @assert out_sz[] == sz
            Error(err) ≠ error_none && return nothing
            data = unsafe_string(pointer(buffer))
            return data
        else
            arrays = [Array{Cchar}(undef, string_array_element_max_size)
                      for i in 1:sz]
            buffers = [pointer(array) for array in arrays]::Vector{Ptr{Cchar}}
            out_sz = Ref{Csize_t}()
            err = ccall((:adios2_attribute_data, libadios2_c), Cint,
                        (Ptr{Ptr{Cchar}}, Ref{Csize_t}, Ptr{Cvoid}), buffers,
                        out_sz, attribute.ptr)
            @assert out_sz[] == sz
            Error(err) ≠ error_none && return nothing
            data = unsafe_string.(buffers)::Vector{String}
            # Use `arrays` again to ensure it is not GCed too early
            buffers .= pointer.(arrays)
            return data
        end
    else
        data = Array{T}(undef, sz)
        out_sz = Ref{Csize_t}()
        err = ccall((:adios2_attribute_data, libadios2_c), Cint,
                    (Ptr{Cvoid}, Ref{Csize_t}, Ptr{Cvoid}), data, out_sz,
                    attribute.ptr)
        @assert out_sz[] == sz
        Error(err) ≠ error_none && return nothing
        isval && return data[1]
        return data
    end
end
