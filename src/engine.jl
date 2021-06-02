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
