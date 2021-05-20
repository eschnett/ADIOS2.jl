module ADIOS2

using ADIOS2_jll
using MPI

### Helpers

const Maybe{T} = Union{Nothing,T}
maybe(::Nothing, other) = other
maybe(x, other) = x

function free(ptr::Ptr)
    @static Sys.iswindows() ? Libc.free(ptr) :
            ccall((:free, libadios2_c), Cvoid, (Ptr{Cvoid},), ptr)
end

### Types

export Error
export error_none, error_invalid_argument, error_system_error,
       error_runtime_error, error_exception
"""
    @enum Error begin
        error_none
        error_invalid_argument
        error_system_error
        error_runtime_error
        error_exception
    end

`Error` return types for all ADIOS2 functions

Based on the [library C++ standardized
exceptions](https://en.cppreference.com/w/cpp/error/exception). Each
error will issue a more detailed description in the standard error
output, stderr
"""
@enum Error begin
    error_none = 0
    error_invalid_argument = 1
    error_system_error = 2
    error_runtime_error = 3
    error_exception = 4
end

@enum AType begin
    type_unknown = -1
    type_string = 0
    type_float = 1
    type_double = 2
    type_float_complex = 3
    type_double_complex = 4
    type_int8_t = 5
    type_int16_t = 6
    type_int32_t = 7
    type_int64_t = 8
    type_uint8_t = 9
    type_uint16_t = 10
    type_uint32_t = 11
    type_uint64_t = 12
    type_long_double = 13
end

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
"""
    @enum Mode begin
        mode_undefined
        mode_write
        mode_read
        mode_append
        mode_deferred
        mode_sync
    end

Mode specifies for various functions. `write`, `read`, `append` are
used for file operations, `deferred`, `sync` are used for get and put
operations.
"""
@enum Mode begin
    mode_undefined = 0
    mode_write = 1
    mode_read = 2
    mode_append = 3
    mode_deferred = 4
    mode_sync = 5
end

export ShapeId
export shapeid_unknown, shapeid_global_value, shapeid_global_array,
       shapeid_joined_array, shapeid_local_value, shapeid_local_array
"""
    @enum ShapeId begin
        shapeid_unknown
        shapeid_global_value
        shapeid_global_array
        shapeid_joined_array
        shapeid_local_value
        shapeid_local_array
    end
"""
@enum ShapeId begin
    shapeid_unknown = -1
    shapeid_global_value = 0
    shapeid_global_array = 1
    shapeid_joined_array = 2
    shapeid_local_value = 3
    shapeid_local_array = 4
end
const shapeid_strings = String["unknown", "global_value", "global_array",
                               "joined_array", "local_value", "local_array"]
shapeid_string(shapeid::ShapeId) = shapeid_strings[Int(shapeid) + 2]
Base.show(io::IO, shapeid::ShapeId) = print(io, shapeid_string(shapeid))

### Adios functions

export Adios
"""
    mutable struct Adios

Holds a C pointer `adios2_adios *`.

This value is finalized automatically. It can also be explicitly
finalized by calling `finalize(adios)`.
"""
mutable struct Adios
    ptr::Ptr{Cvoid}
    Adios(ptr) = finalizer(afinalize, new(ptr))
end
Adios() = Adios(C_NULL)

export init_mpi
"""
    adios = init_mpi(MPI.Comm)
    adios::Union{Adios,Nothing}

Starting point for MPI apps. Creates an ADIOS handler. MPI collective
and it calls `MPI_Comm_dup`.
"""
function init_mpi(comm::MPI.Comm)
    ptr = ccall((:adios2_init_mpi, libadios2_c_mpi), Ptr{Cvoid},
                (MPI.MPI_Comm,), comm)
    return ptr == C_NULL ? nothing : Adios(ptr)
end

export init_serial
"""
    adios = init_serial()
    adios::Union{Adios,Nothing}

Initialize an Adios struct in a serial, non-MPI application. Doesn’t
require a runtime config file.

See also the [ADIOS2
documentation](https://adios2.readthedocs.io/en/latest/api_full/api_full.html#_CPPv418adios2_init_serialv).
"""
function init_serial()
    ptr = ccall((:adios2_init_serial, libadios2_c), Ptr{Cvoid}, ())
    return ptr == C_NULL ? nothing : Adios(ptr)
end

export declare_io
"""
    io = declare_io(adios::Adios, name::AbstractString)
    io::Union{AIO,Nothing}

Declare a new IO handler.

See also the [ADIOS2
documentation](https://adios2.readthedocs.io/en/latest/api_full/api_full.html#_CPPv417adios2_declare_ioP12adios2_adiosPKc).
"""
function declare_io(adios::Adios, name::AbstractString)
    ptr = ccall((:adios2_declare_io, libadios2_c), Ptr{Cvoid},
                (Ptr{Cvoid}, Cstring), adios.ptr, name)
    return ptr == C_NULL ? nothing : AIO(ptr)
end

export afinalize
"""
    err = afinalize(adios::Adios)
    err::Error

Finalize the ADIOS context `adios`. It is usually not necessary to
call this function.

Instead of calling this function, one can also call the finalizer via
`finalize(adios)`. This finalizer is also called automatically when
the Adios object is garbage collected.

See also the [ADIOS2
documentation](https://adios2.readthedocs.io/en/latest/api_full/api_full.html#_CPPv415adios2_finalizeP12adios2_adios)
"""
function afinalize(adios::Adios)
    adios.ptr == C_NULL && return error_none
    err = ccall((:adios2_finalize, libadios2_c), Cint, (Ptr{Cvoid},), adios.ptr)
    adios.ptr = C_NULL
    return Error(err)
end

### IO functions

export AIO
"""
    struct AIO

Holds a C pointer `adios2_io *`.
"""
struct AIO
    ptr::Ptr{Cvoid}
end

export define_variable
"""
    variable = define_variable(io::AIO, name::AbstractString, type::Type,
                         shape::Union{Nothing,CartesianIndex}=nothing,
                         start::Union{Nothing,CartesianIndex}=nothing,
                         count::Union{Nothing,CartesianIndex}=nothing,
                         constant_dims::Bool=false)
    variable::Union{Nothing,Variable}

Define a variable within `io`.

# Arguments
- `io`: handler that owns the variable
- `name`: unique variable identifier
- `type`: primitive type
- `ndims`: number of dimensions
- `shape`: global dimension
- `start`: local offset
- `count`: local dimension
- `constant_dims`: `true`: shape, start, count won't change; `false`:
  shape, start, count will change after definition
"""
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
"""
    variable = inquire_variable(io::AIO, name::AbstractString)
    variable::Union{Nothing,Variable}

Retrieve a variable handler within current `io` handler.

# Arguments
- `io`: handler to variable `io` owner
- `name`: unique variable identifier within `io` handler
"""
function inquire_variable(io::AIO, name::AbstractString)
    ptr = ccall((:adios2_inquire_variable, libadios2_c), Ptr{Cvoid},
                (Ptr{Cvoid}, Cstring), io.ptr, name)
    return ptr == C_NULL ? nothing : Variable(ptr)
end

export inquire_all_variables
"""
    variables = inquire_all_variables(io::AIO)
    variables::Union{Nothing,Vector{Variable}}

Returns an array of variable handlers for all variable present in the
`io` group.

# Arguments
- `io`: handler to variables io owner
"""
function inquire_all_variables(io::AIO)
    c_variables = Ref{Ptr{Ptr{Cvoid}}}()
    size = Ref{Csize_t}()
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
    free(c_variables[])
    return variables
end

"""
    engine = open(io::AIO, name::AbstractString, mode::Mode)
    engine::Union{Nothing,Engine}

 Open an Engine to start heavy-weight input/output operations.

In MPI version reuses the communicator from [`init_mpi`](@ref). MPI
Collective function as it calls `MPI_Comm_dup`.

# Arguments
- `io`: engine owner
- `name`: unique engine identifier
- `mode`: `mode_write`, `mode_read`, `mode_appendq (not yet supported)
"""
function Base.open(io::AIO, name::AbstractString, mode::Mode)
    ptr = ccall((:adios2_open, libadios2_c), Ptr{Cvoid},
                (Ptr{Cvoid}, Cstring, Cint), io.ptr, name, Cint(mode))
    return ptr == C_NULL ? nothing : Engine(ptr)
end

### Variable functions

export Variable
"""
    struct Variable

Holds a C pointer `adios2_variable *`.
"""
struct Variable
    ptr::Ptr{Cvoid}
end

export variable_name
"""
    name = variable_name(variable::Variable)
    name::Union{Nothing,String}

Retrieve variable name.
"""
function variable_name(variable::Variable)
    size = Ref{Csize_t}()
    err = ccall((:adios2_variable_name, libadios2_c), Cint,
                (Ptr{Cchar}, Ref{Csize_t}, Ptr{Cvoid}), C_NULL, size,
                variable.ptr)
    Error(err) ≠ error_none && return nothing
    name = '\0'^size[]
    err = ccall((:adios2_variable_name, libadios2_c), Cint,
                (Ptr{Cchar}, Ref{Csize_t}, Ptr{Cvoid}), name, size,
                variable.ptr)
    Error(err) ≠ error_none && return nothing
    return name
end

export variable_type
"""
    type = variable_type(variable::Variable)
    type::Union{Nothing,Type}

Retrieve variable type.
"""
function variable_type(variable::Variable)
    type = Ref{Cint}()
    err = ccall((:adios2_variable_type, libadios2_c), Cint,
                (Ref{Cint}, Ptr{Cvoid}), type, variable.ptr)
    Error(err) ≠ error_none && return nothing
    return julia_type(AType(type[]))
end

export variable_type_string
"""
    type_string = variable_type(variable::Variable)
    type_string::Union{Nothing,String}

Retrieve variable type in string form "char", "unsigned long", etc.
This reports C type names.
"""
function variable_type_string(variable::Variable)
    size = Ref{Csize_t}()
    err = ccall((:adios2_variable_type_string, libadios2_c), Cint,
                (Ptr{Cchar}, Ref{Csize_t}, Ptr{Cvoid}), C_NULL, size,
                variable.ptr)
    Error(err) ≠ error_none && return nothing
    type = '\0'^size[]
    err = ccall((:adios2_variable_type_string, libadios2_c), Cint,
                (Ptr{Cchar}, Ref{Csize_t}, Ptr{Cvoid}), name, size,
                variable.ptr)
    Error(err) ≠ error_none && return nothing
    return type
end

export variable_shapeid
"""
    shapeid = variable_shapeid(variable::Variable)
    shapeid::Union{Nothing,ShapeId}

Retrieve variable shapeid.
"""
function variable_shapeid(variable::Variable)
    shapeid = Ref{Cint}()
    err = ccall((:adios2_variable_shapeid, libadios2_c), Cint,
                (Ref{Cint}, Ptr{Cvoid}), shapeid, variable.ptr)
    Error(err) ≠ error_none && return nothing
    return ShapeId(shapeid[])
end

export variable_ndims
"""
    ndims = variable_ndims(variable::Variable)
    ndims::Union{Nothing,Int}

Retrieve current variable number of dimensions.
"""
function variable_ndims(variable::Variable)
    ndims = Ref{Csize_t}()
    err = ccall((:adios2_variable_ndims, libadios2_c), Cint,
                (Ref{Cint}, Ptr{Cvoid}), ndims, variable.ptr)
    Error(err) ≠ error_none && return nothing
    return Int(ndims[])
end

export variable_shape
"""
    shape = variable_shape(variable::Variable)
    shape::Union{Nothing,CartesianIndex}

Retrieve current variable shape.
"""
function variable_shape(variable::Variable)
    ndims = variable_ndims(variable)
    shape = Array{Csize_t}(undef, ndims)
    err = ccall((:adios2_variable_shape, libadios2_c), Cint,
                (Ptr{Csize_t}, Ptr{Cvoid}), shape, variable.ptr)
    Error(err) ≠ error_none && return nothing
    return CartesianIndex(shape[]...)
end

export variable_start
"""
    start = variable_start(variable::Variable)
    start::Union{Nothing,CartesianIndex}

Retrieve current variable start.
"""
function variable_start(variable::Variable)
    ndims = variable_ndims(variable)
    start = Array{Csize_t}(undef, ndims)
    err = ccall((:adios2_variable_start, libadios2_c), Cint,
                (Ptr{Csize_t}, Ptr{Cvoid}), start, variable.ptr)
    Error(err) ≠ error_none && return nothing
    return CartesianIndex(start[]...)
end

export variable_count
"""
    count = variable_count(variable::Variable)
    count::Union{Nothing,CartesianIndex}

Retrieve current variable count.
"""
function variable_count(variable::Variable)
    ndims = variable_ndims(variable)
    count = Array{Csize_t}(undef, ndims)
    err = ccall((:adios2_variable_count, libadios2_c), Cint,
                (Ptr{Csize_t}, Ptr{Cvoid}), count, variable.ptr)
    Error(err) ≠ error_none && return nothing
    return CartesianIndex(count[])
end

export variable_steps_start
"""
    steps_start = variable_steps_start(variable::Variable)
    steps_start::Union{Nothing,Int}

Read API, get available steps start from available steps count (e.g.
in a file for a variable).

This returns the absolute first available step, don't use with
`adios2_set_step_selection` as inputs are relative, use `0` instead.
"""
function variable_steps_start(variable::Variable)
    steps_start = Ref{Csize_t}()
    err = ccall((:adios2_variable_steps_start, libadios2_c), Cint,
                (Ref{Csize_t}, Ptr{Cvoid}), steps_start, variable.ptr)
    Error(err) ≠ error_none && return nothing
    return Int(steps_start[])
end

export variable_steps
"""
    steps = variable_steps(variable::Variable)
    steps::Union{Nothing,Int}

Read API, get available steps count from available steps count (e.g.
in a file for a variable). Not necessarily contiguous.
"""
function variable_steps(variable::Variable)
    steps = Ref{Csize_t}()
    err = ccall((:adios2_variable_steps, libadios2_c), Cint,
                (Ref{Csize_t}, Ptr{Cvoid}), steps, variable.ptr)
    Error(err) ≠ error_none && return nothing
    return Int(steps[])
end

export variable_selection_size
"""
    selection_size = variable_selection_size(variable::Variable)
    selection_size::Union{Nothing,Int}

Return the minimum required allocation (in number of elements of a
certain type, not bytes) for the current selection.
"""
function variable_selection_size(variable::Variable)
    selection_size = Ref{Csize_t}()
    err = ccall((:adios2_variable_selection_size, libadios2_c), Cint,
                (Ref{Csize_t}, Ptr{Cvoid}), selection_size, variable.ptr)
    Error(err) ≠ error_none && return nothing
    return Int(selection_size[])
end

export variable_min
"""
    varmin = variable_min(variable::Variable)
    varmin::Union{Nothing,T}

Read mode only: return the absolute minimum for variable.
"""
function variable_min(variable::Variable)
    atype = variable_type(variable)
    atype ≡ nothing && return nothing
    jtype = julia_type(atype)
    varmin = Ref{jtype}()
    err = ccall((:adios2_variable_min, libadios2_c), Cint,
                (Ptr{Cvoid}, Ptr{Cvoid}), varmin, variable.ptr)
    Error(err) ≠ error_none && return nothing
    return varmin[]
end

export variable_max
"""
    varmax = variable_max(variable::Variable)
    varmax::Union{Nothing,T}

Read mode only: return the absolute maximum for variable.
"""
function variable_max(variable::Variable)
    atype = variable_type(variable)
    atype ≡ nothing && return nothing
    jtype = julia_type(atype)
    varmax = Ref{jtype}()
    err = ccall((:adios2_variable_max, libadios2_c), Cint,
                (Ptr{Cvoid}, Ptr{Cvoid}), varmax, variable.ptr)
    Error(err) ≠ error_none && return nothing
    return varmax[]
end

### Attribute functions

### Engine functions

export Engine
"""
    struct Engine

Holds a C pointer `adios2_engine *`.
"""
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
