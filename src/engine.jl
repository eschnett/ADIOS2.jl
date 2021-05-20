# Engine functions

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
