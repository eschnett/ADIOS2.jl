module ADIOS2

using ADIOS2_jll

### Helpers

const Maybe{T} = Union{Nothing,T}
maybe(::Nothing, other) = other
maybe(x, other) = x

### Types

export Error
export error_none, error_invalid_argumet, error_system_error,
       error_runtime_error, error_exception
@enum Error error_none = 0 error_invalid_argumet = 1 error_system_error = 2 error_runtime_error = 3 error_exception = 4

@enum AType type_unknown = -1 type_string = 0 type_float = 1 type_double = 2 type_float_complex = 3 type_double_complex = 4 type_int8_t = 5 type_int16_t = 6 type_int32_t = 7 type_int64_t = 8 type_uint8_t = 9 type_uint16_t = 10 type_uint32_t = 11 type_uint64_t = 12 type_long_double = 13

# We omit `type_long_double` that we cannot handle
const adios_types = AType[type_string, type_float, type_double,
                          type_float_complex, type_double_complex, type_int8_t,
                          type_int16_t, type_int32_t, type_int64_t,
                          type_uint8_t, type_uint16_t, type_uint32_t,
                          type_uint64_t]
adios_type(::Type{String}) = type_string
adios_type(::Type{Float32}) = type_float
adios_type(::Type{Float64}) = type_double
adios_type(::Type{Complex{Float32}}) = type_float_complex
adios_type(::Type{Complex{Float64}}) = type_double_complex
adios_type(::Type{Int8}) = type_int8_t
adios_type(::Type{Int16}) = type_int16_t
adios_type(::Type{Int32}) = type_int32_t
adios_type(::Type{Int64}) = type_int64_t
adios_type(::Type{UInt8}) = type_uint8_t
adios_type(::Type{UInt16}) = type_uint16_t
adios_type(::Type{UInt32}) = type_uint32_t
adios_type(::Type{UInt64}) = type_uint64_t

const julia_types = Type[String, Float32, Float64, Complex{Float32},
                         Complex{Float64}, Int8, Int16, Int32, Int64, UInt8,
                         UInt16, UInt32, UInt64]
julia_type(type::AType) = julia_types[Int(type) + 1]

export Mode
export mode_undefined, mode_write, mode_read, mode_append, mode_deferred,
       mode_sync
@enum Mode mode_undefined = 0 mode_write = 1 mode_read = 2 mode_append = 3 mode_deferred = 4 mode_sync = 5

### Adios functions

export Adios
mutable struct Adios
    ptr::Ptr{Cvoid}
    Adios(ptr) = finalizer(afinalize, new(ptr))
end
Adios() = Adios(C_NULL)

export init_serial
function init_serial()
    ptr = ccall((:adios2_init_serial, libadios2_c), Ptr{Cvoid}, ())
    return ptr == C_NULL ? nothing : Adios(ptr)
end

export declare_io
function declare_io(adios::Adios, name::AbstractString)
    ptr = ccall((:adios2_declare_io, libadios2_c), Ptr{Cvoid},
                (Ptr{Cvoid}, Cstring), adios.ptr, name)
    return ptr == C_NULL ? nothing : AIO(ptr)
end

export afinalize
function afinalize(adios::Adios)
    adios.ptr == C_NULL && return error_none
    err = ccall((:adios2_finalize, libadios2_c), Cint, (Ptr{Cvoid},), adios.ptr)
    adios.ptr = C_NULL
    return Error(err)
end

### IO functions

export AIO
struct AIO
    ptr::Ptr{Cvoid}
end

export define_variable
function define_variable(io::AIO, name::AbstractString, type::Type,
                         shape::Union{Nothing,CartesianIndex}=nothing,
                         start::Union{Nothing,CartesianIndex}=nothing,
                         count::Union{Nothing,CartesianIndex}=nothing,
                         constant_dims::Bool=false)
    ndims = max(length(maybe(shape, ())), length(maybe(start, ())),
                length(maybe(count, ())))
    ptr = ccall((:adios2_define_variable, libadios2_c), Ptr{Cvoid},
                (Ptr{Cvoid}, Cstring, Cint, Csize_t, Ptr{Csize_t}, Ptr{Csize_t},
                 Ptr{Csize_t}, Cint), io.ptr, name, adios_type(type), ndims,
                shape ≡ nothing ? C_NULL : Csize_t[Tuple(shape)...],
                start ≡ nothing ? C_NULL : Csize_t[Tuple(start)...],
                count ≡ nothing ? C_NULL : Csize_t[Tuple(count)...],
                constant_dims)
    return ptr == C_NULL ? nothing : Variable(ptr)
end

function define_variable(io::AIO, name::AbstractString, var::Number)
    return define_variable(io, name, typeof(var))
end
function define_variable(io::AIO, name::AbstractString,
                         arr::AbstractArray{<:Number})
    return define_variable(io, name, eltype(arr), nothing, nothing,
                           CartesianIndex(size(arr)))
end

export inquire_variable
function inquire_variable(io::AIO, name::AbstractString)
    ptr = ccall((:adios2_inquire_variable, libadios2_c), Ptr{Cvoid},
                (Ptr{Cvoid}, Cstring), io.ptr, name)
    return ptr == C_NULL ? nothing : Variable(ptr)
end

export inquire_all_variables
function inquire_all_variables(io::AIO)
    c_variables = Ref{Ptr{Ptr{Cvoid}}}(C_NULL)
    size = Ref{Csize_t}(0)
    err = ccall((:adios2_inquire_all_variables, libadios2_c), Cint,
                (Ref{Ptr{Ptr{Cvoid}}}, Ref{Csize_t}, Ptr{Cvoid}), c_variables,
                size, io.ptr)
    Error(err) ≠ error_none && return nothing
    variables = Array{Variable}(undef, size[])
    for n in 1:length(variables)
        ptr = unsafe_load(c_variables[], n)
        @assert ptr ≠ C_NULL
        variables[n] = Variable(ptr)
    end
    ccall((:free, libadios2_c), Cvoid, (Ptr{Cvoid},), c_variables[])
    return variables
end

function Base.open(io::AIO, name::AbstractString, mode::Mode)
    ptr = ccall((:adios2_open, libadios2_c), Ptr{Cvoid},
                (Ptr{Cvoid}, Cstring, Cint), io.ptr, name, Cint(mode))
    return ptr == C_NULL ? nothing : Engine(ptr)
end

### Variable functions

export Variable
struct Variable
    ptr::Ptr{Cvoid}
end

### Attribute functions

### Engine functions

export Engine
struct Engine
    ptr::Ptr{Cvoid}
    put_sources::Vector{Any}
    get_targets::Vector{Any}
    Engine(ptr) = new(ptr, Any[], Any[])
end

function Base.put!(engine::Engine, variable::Variable,
                   data::Union{Ref,Array,Ptr}, launch::Mode=mode_deferred)
    push!(engine.put_sources, data)
    err = ccall((:adios2_put, libadios2_c), Cint,
                (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Cint), engine.ptr,
                variable.ptr, data, Cint(launch))
    return Error(err)
end
function Base.put!(engine::Engine, variable::Variable, data::Number,
                   launch::Mode=mode_deferred)
    return put!(engine, variable, Ref(data), launch)
end

export perform_puts!
function perform_puts!(engine::Engine)
    err = ccall((:adios2_perform_puts, libadios2_c), Cint, (Ptr{Cvoid},),
                engine.ptr)
    empty!(engine.put_sources)
    return Error(err)
end

function Base.get(engine::Engine, variable::Variable,
                  data::Union{Ref,Array,Ptr}, launch::Mode=mode_deferred)
    push!(engine.get_targets, data)
    err = ccall((:adios2_get, libadios2_c), Cint,
                (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Cint), engine.ptr,
                variable.ptr, data, Cint(launch))
    return Error(err)
end

export perform_gets
function perform_gets(engine::Engine)
    err = ccall((:adios2_perform_gets, libadios2_c), Cint, (Ptr{Cvoid},),
                engine.ptr)
    empty!(engine.get_targets)
    return Error(err)
end

function Base.close(engine::Engine)
    err = ccall((:adios2_close, libadios2_c), Cint, (Ptr{Cvoid},), engine.ptr)
    return Error(err)
end

end
