# Variable functions

export Variable
"""
    struct Variable

Holds a C pointer `adios2_variable *`.
"""
struct Variable
    ptr::Ptr{Cvoid}
    adios::Adios
    Variable(ptr::Ptr{Cvoid}, adios::Adios) = new(ptr, adios)
end

export name
"""
    var_name = name(variable::Variable)
    var_name::Union{Nothing,String}

Retrieve variable name.
"""
function name(variable::Variable)
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

export type
"""
    var_type = type(variable::Variable)
    var_type::Union{Nothing,Type}

Retrieve variable type.
"""
function type(variable::Variable)
    type = Ref{Cint}()
    err = ccall((:adios2_variable_type, libadios2_c), Cint,
                (Ref{Cint}, Ptr{Cvoid}), type, variable.ptr)
    Error(err) ≠ error_none && return nothing
    return julia_type(AType(type[]))
end

# export type_string
# """
#     type_string = variable_type_string(variable::Variable)
#     type_string::Union{Nothing,String}
# 
# Retrieve variable type in string form "char", "unsigned long", etc.
# This reports C type names.
# """
# function type_string(variable::Variable)
#     size = Ref{Csize_t}()
#     err = ccall((:adios2_variable_type_string, libadios2_c), Cint,
#                 (Ptr{Cchar}, Ref{Csize_t}, Ptr{Cvoid}), C_NULL, size,
#                 variable.ptr)
#     Error(err) ≠ error_none && return nothing
#     type = '\0'^size[]
#     err = ccall((:adios2_variable_type_string, libadios2_c), Cint,
#                 (Ptr{Cchar}, Ref{Csize_t}, Ptr{Cvoid}), name, size,
#                 variable.ptr)
#     Error(err) ≠ error_none && return nothing
#     return type
# end

export shapeid
"""
    var_shapeid = shapeid(variable::Variable)
    var_shapeid::Union{Nothing,ShapeId}

Retrieve variable shapeid.
"""
function shapeid(variable::Variable)
    shapeid = Ref{Cint}()
    err = ccall((:adios2_variable_shapeid, libadios2_c), Cint,
                (Ref{Cint}, Ptr{Cvoid}), shapeid, variable.ptr)
    Error(err) ≠ error_none && return nothing
    return ShapeId(shapeid[])
end

"""
    var_ndims = ndims(variable::Variable)
    var_ndims::Union{Nothing,Int}

Retrieve current variable number of dimensions.
"""
function Base.ndims(variable::Variable)
    var_shapeid = shapeid(variable)
    var_shapeid ≡ nothing && return nothing
    var_shapeid == shapeid_local_value && return 0
    ndims = Ref{Csize_t}()
    err = ccall((:adios2_variable_ndims, libadios2_c), Cint,
                (Ref{Csize_t}, Ptr{Cvoid}), ndims, variable.ptr)
    Error(err) ≠ error_none && return nothing
    return Int(ndims[])
end

export shape
"""
    var_shape = shape(variable::Variable)
    var_shape::Union{Nothing,CartesianIndex}

Retrieve current variable shape.
"""
function shape(variable::Variable)
    var_shapeid = shapeid(variable)
    var_shapeid ≡ nothing && return nothing
    var_shapeid ∈ (shapeid_local_value, shapeid_local_array) && return nothing
    D = ndims(variable)
    shape = Array{Csize_t}(undef, D)
    err = ccall((:adios2_variable_shape, libadios2_c), Cint,
                (Ptr{Csize_t}, Ptr{Cvoid}), shape, variable.ptr)
    Error(err) ≠ error_none && return nothing
    return CartesianIndex(reverse!(shape)...)
end

export start
"""
    var_start = start(variable::Variable)
    var_start::Union{Nothing,CartesianIndex}

Retrieve current variable start.
"""
function start(variable::Variable)
    var_shapeid = shapeid(variable)
    var_shapeid ≡ nothing && return nothing
    var_shapeid ∈ (shapeid_local_value, shapeid_local_array) && return nothing
    D = ndims(variable)
    start = Array{Csize_t}(undef, D)
    err = ccall((:adios2_variable_start, libadios2_c), Cint,
                (Ptr{Csize_t}, Ptr{Cvoid}), start, variable.ptr)
    Error(err) ≠ error_none && return nothing
    return CartesianIndex(reverse!(start)...)
end

"""
    var_count = count(variable::Variable)
    var_count::Union{Nothing,CartesianIndex}

Retrieve current variable count.
"""
function Base.count(variable::Variable)
    var_shapeid = shapeid(variable)
    var_shapeid ≡ nothing && return nothing
    var_shapeid == shapeid_local_value && return CartesianIndex()
    D = ndims(variable)
    count = Array{Csize_t}(undef, D)
    err = ccall((:adios2_variable_count, libadios2_c), Cint,
                (Ptr{Csize_t}, Ptr{Cvoid}), count, variable.ptr)
    Error(err) ≠ error_none && return nothing
    return CartesianIndex(reverse!(count)...)
end

export steps_start
"""
    var_steps_start = steps_start(variable::Variable)
    var_steps_start::Union{Nothing,Int}

Read API, get available steps start from available steps count (e.g.
in a file for a variable).

This returns the absolute first available step, don't use with
`adios2_set_step_selection` as inputs are relative, use `0` instead.
"""
function steps_start(variable::Variable)
    steps_start = Ref{Csize_t}()
    err = ccall((:adios2_variable_steps_start, libadios2_c), Cint,
                (Ref{Csize_t}, Ptr{Cvoid}), steps_start, variable.ptr)
    Error(err) ≠ error_none && return nothing
    return Int(steps_start[])
end

export steps
"""
    var_steps = steps(variable::Variable)
    var_steps::Union{Nothing,Int}

Read API, get available steps count from available steps count (e.g.
in a file for a variable). Not necessarily contiguous.
"""
function steps(variable::Variable)
    steps = Ref{Csize_t}()
    err = ccall((:adios2_variable_steps, libadios2_c), Cint,
                (Ref{Csize_t}, Ptr{Cvoid}), steps, variable.ptr)
    Error(err) ≠ error_none && return nothing
    return Int(steps[])
end

export selection_size
"""
    var_selection_size = selection_size(variable::Variable)
    var_selection_size::Union{Nothing,Int}

Return the minimum required allocation (in number of elements of a
certain type, not bytes) for the current selection.
"""
function selection_size(variable::Variable)
    selection_size = Ref{Csize_t}()
    err = ccall((:adios2_variable_selection_size, libadios2_c), Cint,
                (Ref{Csize_t}, Ptr{Cvoid}), selection_size, variable.ptr)
    Error(err) ≠ error_none && return nothing
    return Int(selection_size[])
end

"""
    var_min = minimum(variable::Variable)
    var_min::Union{Nothing,T}

Read mode only: return the absolute minimum for variable.
"""
function Base.minimum(variable::Variable)
    T = type(variable)
    T ≡ nothing && return nothing
    varmin = Ref{T}()
    err = ccall((:adios2_variable_min, libadios2_c), Cint,
                (Ptr{Cvoid}, Ptr{Cvoid}), varmin, variable.ptr)
    Error(err) ≠ error_none && return nothing
    return varmin[]
end

"""
    var_max = maximum(variable::Variable)
    var_max::Union{Nothing,T}

Read mode only: return the absolute maximum for variable.
"""
function Base.maximum(variable::Variable)
    T = type(variable)
    T ≡ nothing && return nothing
    varmax = Ref{T}()
    err = ccall((:adios2_variable_max, libadios2_c), Cint,
                (Ptr{Cvoid}, Ptr{Cvoid}), varmax, variable.ptr)
    Error(err) ≠ error_none && return nothing
    return varmax[]
end
