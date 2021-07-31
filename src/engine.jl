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
    return print(io, "Engine{$nm}")
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
                    data::Union{Ref,Array,Ptr}, launch::Mode=mode_deferred)
    err = Base.put!(engine::Engine, variable::Variable, data::AdiosType,
                    launch::Mode=mode_deferred)
    err::Error

Schedule writing a variable to file. Call `perform_puts!` to perform
the actual write operations.

The reference/array/pointer target must not be modified before
`perform_puts!` is called. It is most efficenty to schedule multiple
`put!` operations before calling `perform_puts!`.
"""
function Base.put!(engine::Engine, variable::Variable,
                   data::Union{Ref,Array,Ptr}, launch::Mode=mode_deferred)
    push!(engine.put_sources, data)
    err = ccall((:adios2_put, libadios2_c), Cint,
                (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Cint), engine.ptr,
                variable.ptr, data, Cint(launch))
    return Error(err)
end
function Base.put!(engine::Engine, variable::Variable, data::AdiosType,
                   launch::Mode=mode_deferred)
    return put!(engine, variable, Ref(data), launch)
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
                   data::Union{Ref,Array,Ptr}, launch::Mode=mode_deferred)
    err::Error

Schedule reading a variable from file into the provided buffer `data`.
Call `perform_gets` to perform the actual read operations.

The reference/array/pointer target must not be modified before
`perform_gets` is called. It is most efficenty to schedule multiple
`get` operations before calling `perform_gets`.
"""
function Base.get(engine::Engine, variable::Variable,
                  data::Union{Ref,Array,Ptr}, launch::Mode=mode_deferred)
    push!(engine.get_targets, data)
    T = type(variable)
    if T ≡ String
        buffer = fill(Cchar(0), string_array_element_max_size)
        err = ccall((:adios2_get, libadios2_c), Cint,
                    (Cstring, Ptr{Cvoid}, Ptr{Cvoid}, Cint), engine.ptr,
                    variable.ptr, buffer, Cint(launch))
        data[] = buffer
    else
        err = ccall((:adios2_get, libadios2_c), Cint,
                    (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Cint), engine.ptr,
                    variable.ptr, data, Cint(launch))
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
