export adios_load
"""
    adios_load(file::AdiosFile, [varName(s)], [step(s)])

Read variable data from ADIOS file with optional variable name(s) and step selection(s).

# Arguments
- First:
  - `file` (::`AdiosFile`): ADIOS file (opened with `mode_readRandomAccess`)
- Second (Optional):
  - `varName` (::`AbstractString`): Single variable name or nothing (reads all)
  - `varNames` (::`AbstractArray{<:AbstractString}``): Array of variable names
  - `name_pattern` (::`Regex`): To find variables whose name contains the pattern (e.g., r"temp.*")
- Third (Optional):
  - `step` (::`Integer`): Single step index (0-based)
  - `step_list` (::`AbstractArray{<:Integer}`): Array of step indices

# Returns
For a variable of N-D data, returns an (N+1)-D array with the last dimension being the steps.

- Single variable:
  - Single step: original dimensionality preserved (N-D array)
  - Multiple steps: returns (N+1)-D array with shape (dim1, dim2, ..., dimN, N_steps)
- Multiple variables:
  - Dictionary with variable names as keys and their data arrays as values

# Examples
```julia
# Open file in random access mode
file = adios_open_serial("simulation.bp", mode_readRandomAccess)

# Read all steps of all variables in the file
data_dict = adios_load(file)

# Read all steps of a variable
data = adios_load(file, "temperature")

# Read of a variable at a specific step
data = adios_load(file, "temperature", 5)

# Read specific steps at multiple steps (order is not sorted)
data = adios_load(file, "temperature", [1,3,6])
data = adios_load(file, "temperature", [6,3,1]) # reverse of previous example
data = adios_load(file, "temperature", 50:100)

# Read multiple variables at a specific step
data_dict = adios_load(file, ["temperature", "pressure"], 5)

# Read multiple variables at multiple steps (order is not sorted)
data_dict = adios_load(file, ["temperature", "pressure"], [1,3,6])
data_dict = adios_load(file, ["temperature", "pressure"], [6,3,1]) # reverse of previous example
data_dict = adios_load(file, ["temperature", "pressure"], 50:100)

# Read multiple variables contain the given name pattern at multiple steps
data_dict = adios_load(file, r"temper", 50:100) # will read (electron_temperature, ion_temperature, abc_temper_abc, etc.)
data_dict = adios_load(file, r"ion.*temper", 50:100) # will read (ion_temperature)
data_dict = adios_load(file, r"temper|pres", 50:100) # will read (temperature, temperature, pressure, ion_pressure, electron_pressure, etc.)

close(file)
```
"""
function adios_load(file::AdiosFile)
    @assert openmode(file.engine) === mode_readRandomAccess "File must be opened with `mode_readRandomAccess`"
    all_varNames = adios_all_variable_names(file)
    return adios_load(file, all_varNames)
end

function adios_load(file::AdiosFile, step::Integer)
    return adios_load(file, [step])
end

function adios_load(file::AdiosFile, step_list::AbstractArray{<:Integer})
    @assert openmode(file.engine) === mode_readRandomAccess "File must be opened with `mode_readRandomAccess`"
    all_varNames = adios_all_variable_names(file)
    return adios_load(file, all_varNames, step_list)
end

function adios_load(file::AdiosFile,
                    varNames::Union{AbstractString,
                                    AbstractArray{<:AbstractString},Regex})
    Nsteps = steps(file.engine)
    if Nsteps == 0
        return adios_load(file, varNames, Val{:no_step})
    else
        step_list = 0:(Nsteps - 1)
        return adios_load(file, varNames, step_list)
    end
end

function adios_load(file::AdiosFile,
                    varNames::Union{AbstractString,
                                    AbstractArray{<:AbstractString},Regex},
                    step::Integer)
    return adios_load(file, varNames, [step])
end

function adios_load(file::AdiosFile, name_pattern::Regex,
                    step_list::AbstractArray{<:Integer})
    varNames = filter(x -> occursin(name_pattern, x),
                      adios_all_variable_names(file))
    if length(varNames) == 1
        return adios_load(file, varNames[1], step_list)
    else
        return adios_load(file, varNames, step_list)
    end
end

# Main fallback function to load a variable
function adios_load(file::AdiosFile, varName::AbstractString,
                    step_list::AbstractArray{<:Integer})
    @assert openmode(file.engine) === mode_readRandomAccess "File must be opened with `mode_readRandomAccess`"
    _check_validity_of_steps(file, step_list)

    # Schedule reading for the requested variable
    ioref = _schedule_tasks_randomAccess(file, varName, step_list)

    # Perform all reads at once
    perform_gets(file.engine)

    return _normalize_data_shape(ioref)
end

# Main fallback function to load mulitple variables
function adios_load(file::AdiosFile, varNames::AbstractArray{<:AbstractString},
                    step_list::AbstractArray{<:Integer})
    @assert openmode(file.engine) === mode_readRandomAccess "File must be opened with `mode_readRandomAccess`"
    _check_validity_of_steps(file, step_list)

    varNames = filter_available_variables(file, varNames)

    # Schedule reading for all requested variables
    Dict_iorefs = Dict{AbstractString,Any}()
    for varName in varNames
        Dict_iorefs[varName] = _schedule_tasks_randomAccess(file, varName,
                                                            step_list)
    end

    # Perform all reads at once
    perform_gets(file.engine)

    results = Dict{AbstractString,Any}()
    for varName in varNames
        results[varName] = _normalize_data_shape(Dict_iorefs[varName])
    end

    return results
end

function adios_load(file::AdiosFile, varName::AbstractString,
                    ::Type{Val{:no_step}})
    return fectch(adios_get(file, varName))
end

function adios_load(file::AdiosFile, varNames::AbstractArray{<:AbstractString},
                    ::Type{Val{:no_step}})
    varNames = filter_available_variables(file, varNames)

    results = Dict{AbstractString,Any}()
    for varName in varNames
        results[varName] = adios_load(file, varName, Val{:no_step})
    end

    return results
end

function adios_load(file::AdiosFile, name_pattern::Regex, ::Type{Val{:no_step}})
    varNames = filter(x -> occursin(name_pattern, x),
                      adios_all_variable_names(file))
    return adios_load(file, varNames, Val{:no_step})
end

# Convenience dispatches for loading from a file path or directory
"""
    adios_load(bpPath::AbstractString)
    adios_load(bpPath::AbstractString, args...)

Convenient highest-level API to read variable data directly from ADIOS's BP file path.

This is a convenience wrapper that automatically opens the file in `mode_readRandomAccess`,
reads the data, and closes the file. All the functionality of `adios_load(file::AdiosFile, ...)`
is available through the same argument patterns.

# Arguments
- `bpPath` (`AbstractString`): Path to ADIOS's BP file/directory ending with `.bp` extension
- `args...`: Same arguments as `adios_load(file::AdiosFile, ...)` - variable names, steps, etc.

# Returns
Same return types as `adios_load(file::AdiosFile, ...)`:
- Single variable, single step: N-D array
- Single variable, multiple steps: (N+1)-D array with steps as last dimension
- Multiple variables: Dictionary with variable names as keys

# Examples
```julia
# Read all variables and all steps
data_dict = adios_load("simulation.bp")

# Read specific variable, all steps
temperature = adios_load("simulation.bp", "temperature")

# Read specific variable at specific step
temp_step5 = adios_load("simulation.bp", "temperature", 5)

# Read multiple variables at multiple steps
data = adios_load("simulation.bp", ["temperature", "pressure"], [1,3,5])

# Read variables matching pattern
temps = adios_load("simulation.bp", r".*temperature.*", 10:20)
```

# Notes
- File is automatically opened with `mode_readRandomAccess` and closed after reading
- Throws `ErrorException` if the file path does not exist or is invalid
- More efficient to use `adios_load(file::AdiosFile, ...)` directly if reading multiple times
  from the same file to avoid repeated open/close operations

See also: [`adios_load(::AdiosFile)`](@ref), [`adios_open_serial`](@ref)
"""
function adios_load(bpPath::AbstractString)
    if (isdir(bpPath) || isfile(bpPath)) && endswith(bpPath, ".bp")
        file = adios_open_serial(bpPath, mode_readRandomAccess)
        result = adios_load(file)
        close(file)
        return result
    else
        error("$bpPath is not valid or not ending with `.bp` extension \n")
    end
end

function adios_load(bpPath::AbstractString, args...)
    if (isdir(bpPath) || isfile(bpPath))  && endswith(bpPath, ".bp")
        file = adios_open_serial(bpPath, mode_readRandomAccess)
        result = adios_load(file, args...)
        close(file)
        return result
    else
        error("$bpPath is not valid or not ending with `.bp` extension \n")
    end
end


# Check if steps are valid for the given ADIOS file.
function _check_validity_of_steps(file::AdiosFile,
                                  step_list::AbstractArray{<:Integer})
    total_steps = steps(file.engine)
    if total_steps === nothing || total_steps <= 0
        error("Cannot determine number of steps in file or file has no steps")
    end

    if minimum(step_list) < 0 || maximum(step_list) >= total_steps
        error("Invalid step range: min=$(minimum(step_list)) & max=$(maximum(step_list)) (valid range: 0 to $(total_steps-1))")
    end
    return true
end

# Filter variable names to only those that exist in the ADIOS file.
# Prints a warning for variables that are not found.
function filter_available_variables(file::AdiosFile,
                                    varNames::AbstractArray{<:AbstractString})
    available_vars = String[]
    sizehint!(available_vars, length(varNames))

    for varName in varNames
        var = inquire_variable(file.io, varName)
        if var === nothing
            @warn "Variable '$varName' not found in the file, skipping..."
        else
            push!(available_vars, varName)
        end
    end

    return available_vars
end

# Schedule variable reading tasks in mode_readRandomAccess for specified steps.
# Returns array of IORef objects ready for batch processing.
function _schedule_tasks_randomAccess(file::AdiosFile, varName::AbstractString,
                                      steps::AbstractArray{<:Integer})
    var = inquire_variable(file.io, varName)
    if var === nothing
        error("Variable '$varName' not found in the file")
    end
    T, D, sh = _get_var_type_ndims_shape(var)

    # Schedule reading for all requested steps
    iorefs = IORef[]
    sizehint!(iorefs, length(steps))
    for step in steps
        set_step_selection(var, step, 1)

        # Schedule reading data for the current step
        ioref = IORef{T,D}(file.engine, Array{T,D}(undef, Tuple(sh)))
        get(file.engine, var, ioref.array)
        push!(file.engine.get_tasks, () -> (ioref.engine = nothing))
        push!(iorefs, ioref)
    end

    return iorefs
end

function _schedule_tasks_randomAccess(file::AdiosFile, varName::AbstractString,
                                      step_list::UnitRange{<:Integer})
    @assert minimum(step_list) >= 0 "Steps must be non-negative integers"
    @assert maximum(step_list) < steps(file.engine) "Steps must be less than total steps"

    var = inquire_variable(file.io, varName)
    if var === nothing
        error("Variable '$varName' not found in the file")
    end
    T, D, sh = _get_var_type_ndims_shape(var)

    # For contiguous UnitRange, create a single IORef
    set_step_selection(var, step_list[1], length(step_list))

    ioref = IORef{T,D + 1}(file.engine,
                           Array{T,D + 1}(undef, (sh..., length(step_list))))
    get(file.engine, var, ioref.array)
    push!(file.engine.get_tasks, () -> (ioref.engine = nothing))

    return ioref
end

# Normalize data shape from IORef objects for consistent output format.
# Returns data in the appropriate dimensionality based on content.
# Handles both scalar and array data properly with steps as the last dimension.
function _normalize_data_shape(ioref::IORef)
    @assert isready(ioref) "IORefs must be ready before assembling data"

    if ndims(ioref.array) == 2 && size(ioref.array, 1) == 1
        # This is a collection of scalar
        # return it as a Vector, not as a Matrix
        result = ioref.array[:]
    else
        # Otherwise, return it as is
        result = ioref.array
    end

    return result
end

function _normalize_data_shape(iorefs::AbstractArray{<:IORef})
    @assert all(isready.(iorefs)) "All IORefs must be ready before assembling data"

    N_steps = length(iorefs)

    # Create result array with time as the last dimension (column-major optimized)
    # Get dimensions from the first IORef's data
    data_arr = [fetch(ioref) for ioref in iorefs]
    dims = size(data_arr[1])
    T = eltype(data_arr[1])

    # Create the final array with time as the last dimension
    result_shape = (dims..., N_steps)
    last_index = findlast(x -> x != 1, result_shape)

    if last_index === nothing
        # scalar
        result = data_arr[1][]
    else
        # Array
        result_shape = result_shape[1:last_index]
        if result_shape[1] == 1
            result_shape = result_shape[2:end]
        end

        D = length(result_shape)

        result = Array{T,D}(undef, result_shape)

        if N_steps == 1
            @views result .= data_arr[1]
        else
            # Copy data from each step into the result array
            for i in 1:N_steps
                selectdim(result, D, i) .= data_arr[i]
            end
        end
    end

    return result
end

# Get variable data type and dimensions
function _get_var_type_ndims_shape(var::Variable)
    T = type(var)
    if T === nothing
        error("Cannot determine type of variable '$varName'")
    end

    D = ndims(var)
    if D === nothing
        error("Cannot determine dimensions of variable '$varName'")
    end

    sh = count(var)
    if sh === nothing
        error("Cannot determine shape of variable '$varName'")
    end
    return T, D, sh
end
