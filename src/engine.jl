# Engine functions

export Engine
"""
    struct Engine

Holds a C pointer `adios2_engine *`.
"""
struct Engine
    ptr::Ptr{Cvoid}
    adios::Adios
    put_sources::Vector{Any}
    get_targets::Vector{Any}
    get_tasks::Vector{Function}
    function Engine(ptr::Ptr{Cvoid}, adios::Adios)
        return new(ptr, adios, Any[], Any[], Function[])
    end
end

function Base.show(io::IO, ::MIME"text/plain", engine::Engine)
    nm = name(engine)
    return print(io, "Engine($nm)")
end

export name
"""
    engine_name = name(engine::Engine)
    engine_name::Union{Nothing,String}

Retrieve engine name.
"""
function name(engine::Engine)
    size = Ref{Csize_t}()
    err = ccall((:adios2_engine_name, libadios2_c), Cint,
                (Ptr{Cchar}, Ref{Csize_t}, Ptr{Cvoid}), C_NULL, size,
                engine.ptr)
    Error(err) ≠ error_none && return nothing
    name = Array{Cchar}(undef, size[])
    err = ccall((:adios2_engine_name, libadios2_c), Cint,
                (Ptr{Cchar}, Ref{Csize_t}, Ptr{Cvoid}), name, size, engine.ptr)
    Error(err) ≠ error_none && return nothing
    return unsafe_string(pointer(name), size[])
end

export type
"""
    engine_type = type(engine::Engine)
    engine_type::Union{Nothing,String}

Retrieve engine type.
"""
function type(engine::Engine)
    size = Ref{Csize_t}()
    err = ccall((:adios2_engine_get_type, libadios2_c), Cint,
                (Ptr{Cchar}, Ref{Csize_t}, Ptr{Cvoid}), C_NULL, size,
                engine.ptr)
    Error(err) ≠ error_none && return nothing
    type = Array{Cchar}(undef, size[])
    err = ccall((:adios2_engine_get_type, libadios2_c), Cint,
                (Ptr{Cchar}, Ref{Csize_t}, Ptr{Cvoid}), type, size, engine.ptr)
    Error(err) ≠ error_none && return nothing
    return unsafe_string(pointer(type), size[])
end

export openmode
"""
    engine_openmode = openmode(engine::Engine)
    engine_openmode::Union{Nothing,Mode}

Retrieve engine openmode.
"""
function openmode(engine::Engine)
    mode = Ref{Cint}()
    err = ccall((:adios2_engine_openmode, libadios2_c), Cint,
                (Ptr{Cint}, Ptr{Cvoid}), mode, engine.ptr)
    Error(err) ≠ error_none && return nothing
    return Mode(mode[])
end

export begin_step
"""
    status = begin_step(engine::Engine, mode::StepMode,
                        timeout_seconds::Union{Integer,AbstractFloat})
    status = begin_step(engine::Engine)
    status::Union{Noting,StepStatus}

Begin a logical adios2 step stream.
"""
function begin_step(engine::Engine, mode::StepMode,
                    timeout_seconds::Union{Integer,AbstractFloat})
    status = Ref{Cint}()
    err = ccall((:adios2_begin_step, libadios2_c), Cint,
                (Ptr{Cvoid}, Cint, Cfloat, Ptr{Cint}), engine.ptr, mode,
                timeout_seconds, status)
    Error(err) ≠ error_none && return nothing
    return StepStatus(status[])
end
function begin_step(engine::Engine)
    if openmode(engine) == mode_read
        return begin_step(engine, step_mode_read, -1)
    else
        return begin_step(engine, step_mode_append, -1)
    end
end

export current_step
"""
    step = current_step(engine::Engine)
    step::Union{Noting,Int}

Inspect current logical step.
"""
function current_step(engine::Engine)
    step = Ref{Csize_t}()
    err = ccall((:adios2_current_step, libadios2_c), Cint,
                (Ptr{Csize_t}, Ptr{Cvoid}), step, engine.ptr)
    Error(err) ≠ error_none && return nothing
    return Int(step)
end

export steps
"""
    step = steps(engine::Engine)
    step::Union{Noting,Int}

Inspect total number of available steps.
"""
function steps(engine::Engine)
    steps = Ref{Csize_t}()
    err = ccall((:adios2_steps, libadios2_c), Cint, (Ptr{Csize_t}, Ptr{Cvoid}),
                steps, engine.ptr)
    Error(err) ≠ error_none && return nothing
    return Int(steps[])
end

"""
    err = Base.put!(engine::Engine, variable::Variable,
                    data::Union{Ref,DenseArray,SubArray,Ptr},
                    launch::Mode=mode_deferred)
    err = Base.put!(engine::Engine, variable::Variable, data::AdiosType,
                    launch::Mode=mode_deferred)
    err::Error

Schedule writing a variable to file. The buffer `data` must be
contiguous in memory.

Call `perform_puts!` to perform the actual write operations.

The reference/array/pointer target must not be modified before
`perform_puts!` is called. It is most efficient to schedule multiple
`put!` operations before calling `perform_puts!`.
"""
function Base.put!(engine::Engine, variable::Variable,
                   data::Union{Ref,DenseArray,SubArray,Ptr},
                   launch::Mode=mode_deferred)
    if data isa AbstractArray && length(data) ≠ 0
        np = 1
        for (str, sz) in zip(strides(data), size(data))
            str ≠ np &&
                throw(ArgumentError("ADIOS2: `data` argument to `put!` must be contiguous"))
            np *= sz
        end
    end
    T = type(variable)
    if T ≡ String
        eltype(data) <: Union{Cchar,Cuchar} ||
            throw(ArgumentError("ADIOS2: `data` element type for string variables must be either `Cchar` or `Cuchar`"))
    else
        eltype(data) ≡ T ||
            throw(ArgumentError("ADIOS2: `data` element type for non-string variables must be the same as the variable type"))
    end
    co = count(variable)
    len = data isa Ptr ? typemax(Int) : length(data)
    (co ≡ nothing ? 1 : prod(co)) ≤ len ||
        throw(ArgumentError("ADIOS2: `data` length must be at least as large as the count of the variable"))
    if launch ≡ mode_deferred
        push!(engine.put_sources, (engine, variable, data))
    end
    err = ccall((:adios2_put, libadios2_c), Cint,
                (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Cint), engine.ptr,
                variable.ptr, data, Cint(launch))
    return Error(err)
end
function Base.put!(engine::Engine, variable::Variable, data::AdiosType,
                   launch::Mode=mode_deferred)
    return put!(engine, variable, Ref(data), launch)
end
function Base.put!(engine::Engine, variable::Variable, data::AbstractString,
                   launch::Mode=mode_deferred)
    if launch ≡ mode_deferred
        push!(engine.put_sources, data)
    end
    return put!(engine, variable, pointer(data), launch)
end

export perform_puts!
"""
    perform_puts!(engine::Engine)

Execute all currently scheduled write operations.
"""
function perform_puts!(engine::Engine)
    err = ccall((:adios2_perform_puts, libadios2_c), Cint, (Ptr{Cvoid},),
                engine.ptr)
    empty!(engine.put_sources)
    return Error(err)
end

"""
    err = Base.get(engine::Engine, variable::Variable,
                   data::Union{Ref,DenseArray,SubArray,Ptr},
                   launch::Mode=mode_deferred)
    err::Error

Schedule reading a variable from file into the provided buffer `data`.
`data` must be contiguous in memory.

Call `perform_gets` to perform the actual read operations.

The reference/array/pointer target must not be modified before
`perform_gets` is called. It is most efficient to schedule multiple
`get` operations before calling `perform_gets`.
"""
function Base.get(engine::Engine, variable::Variable,
                  data::Union{Ref,DenseArray,SubArray,Ptr},
                  launch::Mode=mode_deferred)
    if data isa AbstractArray && !isempty(data)
        np = 1
        for (str, sz) in zip(strides(data), size(data))
            str ≠ np &&
                throw(ArgumentError("ADIOS2: `data` argument to `get` must be contiguous"))
            np *= sz
        end
    end
    co = count(variable)
    len = data isa Ptr ? typemax(Int) : length(data)
    (co ≡ nothing ? 1 : prod(co)) ≤ len ||
        throw(ArgumentError("ADIOS2: `data` length must be at least as large as the count of the variable"))
    T = type(variable)
    if T ≡ String
        eltype(data) <: AbstractString ||
            throw(ArgumentError("ADIOS2: `data` element type for string variables must be a subtype of `AbstractString`"))
        buffer = fill(Cchar(0), string_array_element_max_size + 1)
        err = ccall((:adios2_get, libadios2_c), Cint,
                    (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Cint), engine.ptr,
                    variable.ptr, buffer, Cint(launch))
        if launch ≡ mode_deferred
            push!(engine.get_targets, (engine, variable))
            if data isa Ref
                push!(engine.get_tasks,
                      () -> data[] = unsafe_string(pointer(buffer)))
            else
                push!(engine.get_tasks,
                      () -> data[begin] = unsafe_string(pointer(buffer)))
            end
        else
            data[] = unsafe_string(pointer(buffer))
        end
    else
        eltype(data) ≡ T ||
            throw(ArgumentError("ADIOS2: `data` element type for non-string variables must be the same as the variable type"))
        err = ccall((:adios2_get, libadios2_c), Cint,
                    (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Cint), engine.ptr,
                    variable.ptr, data, Cint(launch))
        if launch ≡ mode_deferred
            push!(engine.get_targets, (engine, variable, data))
        end
    end
    return Error(err)
end

export perform_gets
"""
    perform_gets(engine::Engine)

Execute all currently scheduled read operations.
"""
function perform_gets(engine::Engine)
    err = ccall((:adios2_perform_gets, libadios2_c), Cint, (Ptr{Cvoid},),
                engine.ptr)
    empty!(engine.get_targets)
    for task in engine.get_tasks
        task()
    end
    empty!(engine.get_tasks)
    return Error(err)
end

export end_step
"""
    end_step(engine::Engine)

Terminate interaction with current step.
"""
function end_step(engine::Engine)
    err = ccall((:adios2_end_step, libadios2_c), Cint, (Ptr{Cvoid},),
                engine.ptr)
    empty!(engine.get_targets)
    for task in engine.get_tasks
        task()
    end
    empty!(engine.get_tasks)
    return Error(err)
end

"""
    flush(engine::Engine)

Flush all buffered data to file. Call this after `perform_puts!` to
ensure data are actually written to file.
"""
function Base.flush(engine::Engine)
    err = ccall((:adios2_flush, libadios2_c), Cint, (Ptr{Cvoid},), engine.ptr)
    return Error(err)
end

"""
    close(engine::Engine)

Close a file. This implicitly also flushed all buffered data.
"""
function Base.close(engine::Engine)
    err = ccall((:adios2_close, libadios2_c), Cint, (Ptr{Cvoid},), engine.ptr)
    return Error(err)
end
