# Julia-specific high-level API

################################################################################

export AdiosFile
"""
    struct AdiosFile

Context for the high-level API for an ADIOS file
"""
struct AdiosFile
    adios::Adios
    io::AIO
    engine::Engine
    AdiosFile(adios::Adios, io::AIO, engine::Engine) = new(adios, io, engine)
end

export adios_open_serial
"""
    adios = adios_open_serial(filename::AbstractString, mode::Mode)
    adios::AdiosFile

Open an ADIOS file. Use `mode = mode_write` for writing and `mode =
mode_read` for reading.
"""
function adios_open_serial(filename::AbstractString, mode::Mode)
    adios = adios_init_serial()
    io = declare_io(adios, "IO")
    engine = open(io, filename, mode)
    return AdiosFile(adios, io, engine)
end

export adios_open_mpi
"""
    adios = adios_open_mpi(comm::MPI.Comm, filename::AbstractString, mode::Mode)
    adios::AdiosFile

Open an ADIOS file for parallel I/O. Use `mode = mode_write` for
writing and `mode = mode_read` for reading.
"""
function adios_open_mpi(comm::MPI.Comm, filename::AbstractString, mode::Mode)
    adios = adios_init_mpi(comm)
    io = declare_io(adios, "IO")
    engine = open(io, filename, mode)
    return AdiosFile(adios, io, engine)
end

"""
    flush(file::AdiosFile)

Flush an ADIOS file. When writing, flushing or closing a file is
necesssary to ensure that data are actually written to the file.
"""
function Base.flush(file::AdiosFile)
    flush(file.engine)
    return nothing
end

"""
    close(file::AdiosFile)

Close an ADIOS file. When writing, flushing or closing a file is
necesssary to ensure that data are actually written to the file.
"""
function Base.close(file::AdiosFile)
    close(file.engine)
    adios_finalize(file.adios)
    return nothing
end

################################################################################

export adios_subgroup_names
"""
    groups = adios_subgroup_names(file::AdiosFile, groupname::AbstractString)
    vars::Vector{String}

List (non-recursively) all subgroups in the group `groupname` in the
file.
"""
function adios_subgroup_names(file::AdiosFile, groupname::AbstractString)
    vars = inquire_subgroups(file.io, groupname)
    vars ≡ nothing && return String[]
    return vars
end

export adios_define_attribute
"""
   adios_define_attribute(file::AdiosFile, name::AbstractString,
                          value::AdiosType)

Write a scalar attribute.
"""
function adios_define_attribute(file::AdiosFile, name::AbstractString,
                                value::AdiosType)
    define_attribute(file.io, name, value)
    return nothing
end

"""
    adios_define_attribute(file::AdiosFile, name::AbstractString,
                           value::AbstractArray{<:AdiosType})

Write an array-valued attribute.
"""
function adios_define_attribute(file::AdiosFile, name::AbstractString,
                                value::AbstractArray{<:AdiosType})
    define_attribute_array(file.io, name, value)
    return nothing
end

"""
    adios_define_attribute(file::AdiosFile, path::AbstractString,
                           name::AbstractString, value::AdiosType)

Write a scalar attribute into the path `path` in the file.
"""
function adios_define_attribute(file::AdiosFile, path::AbstractString,
                                name::AbstractString, value::AdiosType)
    define_variable_attribute(file.io, name, value, path)
    return nothing
end

"""
    adios_define_attribute(file::AdiosFile, path::AbstractString,
                           name::AbstractString,
                           value::AbstractArray{<:AdiosType})

Write an array-valued attribute into the path `path` in the file.
"""
function adios_define_attribute(file::AdiosFile, path::AbstractString,
                                name::AbstractString,
                                value::AbstractArray{<:AdiosType})
    define_variable_attribute_array(file.io, name, value, path)
    return nothing
end

export adios_all_attribute_names
"""
    attrs = adios_all_attribute_names(file::AdiosFile)
    attrs::Vector{String}

List (recursively) all attributes in the file.
"""
function adios_all_attribute_names(file::AdiosFile)
    attrs = inquire_all_attributes(file.io)
    attrs ≡ nothing && return String[]
    return name.(attrs)
end

export adios_group_attribute_names
"""
    vars = adios_group_attribute_names(file::AdiosFile, groupname::AbstractString)
    vars::Vector{String}

List (non-recursively) all attributes in the group `groupname` in the
file.
"""
function adios_group_attribute_names(file::AdiosFile, groupname::AbstractString)
    vars = inquire_group_attributes(file.io, groupname)
    vars ≡ nothing && return String[]
    return name.(vars)
end

export adios_attribute_data
"""
    attr_data = adios_attribute_data(file::AdiosFile, name::AbstractString)
    attr_data::Union{Nothing,AdiosType}

Read an attribute from a file. Return `nothing` if the attribute is
not found.
"""
function adios_attribute_data(file::AdiosFile, name::AbstractString)
    attr = inquire_attribute(file.io, name)
    attr ≡ nothing && return nothing
    attr_data = data(attr)
    return attr_data
end

"""
    attr_data =  adios_attribute_data(file::AdiosFile, path::AbstractString,
                                      name::AbstractString)
    attr_data::Union{Nothing,AdiosType}

Read an attribute from a file in path `path`. Return `nothing` if the
attribute is not found.
"""
function adios_attribute_data(file::AdiosFile, path::AbstractString,
                              name::AbstractString)
    attr = inquire_variable_attribute(file.io, name, path)
    attr ≡ nothing && return nothing
    attr_data = data(attr)
    return attr_data
end

################################################################################

export adios_put!
"""
   adios_put!(file::AdiosFile, name::AbstractString, scalar::AdiosType)

Schedule writing a scalar variable to a file.

The variable is not written until `adios_perform_puts!` is called and
the file is flushed or closed.
"""
function adios_put!(file::AdiosFile, name::AbstractString, scalar::AdiosType)
    var = inquire_variable(file.io, name)
    if isnothing(var)
        var = define_variable(file.io, name, scalar)
    end
    put!(file.engine, var, scalar)
    return var
end

"""
    adios_put!(file::AdiosFile, name::AbstractString,
               array::AbstractArray{<:AdiosType}; make_copy::Bool=false)

Schedule writing an array-valued variable to a file.

`make_copy` determines whether to make a copy of the array, which is
expensive for large arrays. When no copy is made, then the array must
not be modified before `adios_perform_puts!` is called.

The variable is not written until `adios_perform_puts!` is called and
the file is flushed or closed.
"""
function adios_put!(file::AdiosFile, name::AbstractString,
                    array::AbstractArray{<:AdiosType}; make_copy::Bool=false)
    # 0-dimensional arrays need to be passed as scalars
    ndims(array) == 0 &&
        return adios_put!(file, name, make_copy ? copy(array)[] : array[])

    var = inquire_variable(file.io, name)
    if isnothing(var)
        var = define_variable(file.io, name, array)
    end
    put!(file.engine, var, make_copy ? copy(array) : array)
    return var
end

export adios_perform_puts!
"""
    adios_perform_puts!(file::AdiosFile)

Execute all scheduled `adios_put!` operations.

The data might not be in the file yet; they might be buffered. Call
`adios_flush` or `adios_close` to ensure all data are written to file.
"""
function adios_perform_puts!(file::AdiosFile)
    perform_puts!(file.engine)
    return nothing
end

export adios_all_variable_names
"""
    vars = adios_all_variable_names(file::AdiosFile)
    vars::Vector{String}

List (recursively) all variables in the file.
"""
function adios_all_variable_names(file::AdiosFile)
    vars = inquire_all_variables(file.io)
    vars ≡ nothing && return String[]
    return name.(vars)
end

export adios_group_variable_names
"""
    vars = adios_group_variable_names(file::AdiosFile, groupname::AbstractString)
    vars::Vector{String}

List (non-recursively) all variables in the group `groupname` in the
file.
"""
function adios_group_variable_names(file::AdiosFile, groupname::AbstractString)
    vars = inquire_group_variables(file.io, groupname)
    vars ≡ nothing && return String[]
    return name.(vars)
end

export IORef
"""
    mutable struct IORef{T,D}

A reference to the value of a variable that has been scheduled to be
read from disk. This value cannot be accessed bofre the read
operations have actually been executed.

Use `fetch(ioref::IORef)` to access the value. `fetch` will trigger
the actual reading from file if necessary. It is most efficient to
schedule multiple read operations at once.

Use `adios_perform_gets` to trigger reading all currently scheduled
variables.
"""
mutable struct IORef{T,D}
    engine::Union{Nothing,Engine}
    array::Array{T,D}
    function IORef{T,D}(engine::Engine, array::Array{T,D}) where {T,D}
        return new{T,D}(engine, array)
    end
end

"""
    isready(ioref::IORef)::Bool

Check whether an `IORef` has already been read from file.
"""
Base.isready(ioref::IORef) = ioref.engine ≡ nothing

"""
    value = fetch(ioref::IORef{T,D}) where {T,D}
    value::Array{T,D}

Access an `IORef`. If necessary, the variable is read from file and
then cached. (Each `IORef` is read at most once.)

Scalars are handled as zero-dimensional arrays. To access the value of
a zero-dimensional array, write `array[]` (i.e. use array indexing,
but without any indices).
"""
function Base.fetch(ioref::IORef)
    isready(ioref) || perform_gets(ioref.engine)
    @assert isready(ioref)
    # return 0-D arrays as scalars
    # D == 0 && return ioref.array[]
    return ioref.array
end

export adios_get
"""
    ioref = adios_get(file::AdiosFile, name::AbstractString)
    ioref::Union{Nothing,IORef}

Schedule reading a variable from a file.

The variable is not read until `adios_perform_gets` is called. This
happens automatically when the `IORef` is accessed (via `fetch`). It
is most efficient to first schedule multiple variables for reading,
and then executing the reads together.
"""
function adios_get(file::AdiosFile, name::AbstractString)
    var = inquire_variable(file.io, name)
    var ≡ nothing && return nothing
    T = type(var)
    T ≡ nothing && return nothing
    D = ndims(var)
    D ≡ nothing && return nothing
    sh = count(var)
    sh ≡ nothing && return nothing
    ioref = IORef{T,D}(file.engine, Array{T,D}(undef, Tuple(sh)))
    get(file.engine, var, ioref.array)
    push!(file.engine.get_tasks, () -> (ioref.engine = nothing))
    return ioref
end

export adios_perform_gets
"""
    adios_perform_gets(file::AdiosFile)

Execute all currently scheduled read opertions. This makes all pending
`IORef`s ready.
"""
function adios_perform_gets(file::AdiosFile)
    perform_gets(file.engine)
    return nothing
end
