# ADIOS2.jl

A Julia interface to [ADIOS2](https://github.com/ornladios/ADIOS2),
the Adaptable Input Output System version 2.

* [![Documenter](https://img.shields.io/badge/docs-dev-blue.svg)](https://eschnett.github.io/ADIOS2.jl/dev)
* [![GitHub
  CI](https://github.com/eschnett/ADIOS2.jl/workflows/CI/badge.svg)](https://github.com/eschnett/ADIOS2.jl/actions)
* [![Codecov](https://codecov.io/gh/eschnett/ADIOS2.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/eschnett/ADIOS2.jl)

## Examples

It is best to read the ADIOS2 documentation before using this package.

ADIOS2 splits reading/writing variables into three parts:
1. Define the metadata, i.e. the name, type, and shape (if array) of
   the variables
2. Schedule the reads/writes, providing pointers to or buffer for the
   data
3. Perform the actual reads/writes

This ensures that reads or writes can be performed very efficiently.

### Writing a file

```Julia
# Initialize ADIOS
using ADIOS2
adios = adios_init_serial()
io = declare_io(adios, "IO")
engine = open(io, "example.bp", mode_write)

# Define some variables
scalar = 247.0
svar = define_variable(io, "scalar", scalar)
array = Float64[10i + j for i in 1:2, j in 1:3]
avar = define_variable(io, "array", array)

# Schedule writing the variables
put!(engine, svar, scalar)
put!(engine, avar, array)

# Write the variables
perform_puts!(engine)
close(engine)
```

### Reading a file

```Julia
# Initialize ADIOS
using ADIOS2
adios = adios_init_serial()
io = declare_io(adios, "IO")
engine = open(io, "example.bp", mode_read)

# List all variables
vars = inquire_all_variables(io)
println("Variables:")
for var in vars
    println("    ", name(var))
end
svar = inquire_variable(io, "scalar")
avar = inquire_variable(io, "array")

# Schedule reading the variables
scalar = Ref{Float64}()
get(engine, svar, scalar)
array = Array{Float64}(undef, 2, 3)
get(engine, avar, array)

# Read the variables
perform_gets(engine)

println("scalar: $(scalar[])")
println("array: $array")
```


## Time-series data with steps

`ADIOS2` supports the concept of **`steps`**, which allows storing time-series or iteration-based data efficiently. Each step can contain a complete snapshot of all variables at a particular point in time or iteration.

### Writing a file with multiple steps

```Julia
using ADIOS2

Nsteps = 10
file = adios_open_serial("test.bp", mode_write)
for i in 0:(Nsteps - 1)
   begin_step(file.engine)

   # schedule writing the variables
   adios_put!(file, "step", i)

   adios_put!(file, "scalar", rand())
   adios_put!(file, "vector", rand(2))
   adios_put!(file, "matrix", rand(2,2))
   adios_put!(file, "array3D", rand(2,2,2))
   adios_put!(file, "array4D", rand(2,2,2,2))
   adios_put!(file, "array5D", rand(2,2,2,2,2))

   # Write the variables
   adios_perform_puts!(file)

   end_step(file.engine)
end
close(file)
```

### Reading a file using high-level API

`ADIOS2.jl` provides a high-level API through the `adios_load` function, which greatly simplifies reading data. This API automatically handles dimensionality and steps, making it easy to work with time-series data.

The `adios_load` function automatically handles the dimensionality of data:

1. For scalar variables:
   - Single step: Returns the scalar value
   - Multiple steps: Returns a 1D array with values at each step

2. For array variables (N-D):
   - Single step: Returns an N-D array
   - Multiple steps: Returns an (N+1)-D array with the last dimension being the steps


```Julia
using ADIOS2

# Open file in random access mode for efficient reading of any step
file = adios_open_serial("test.bp", mode_readRandomAccess)

# Retruns a Dictionary of all variables at all steps
all_data = adios_load(file)

# julia> all_data
# Dict{AbstractString, Any} with 7 entries:
#   "step"    => [0, 1, 2, 3, 4]
#   "vector"  => [0.081135 0.207559 … 0.934734 0.5384…
#   "array3D" => [0.137995 0.157526; 0.198498 0.68091…
#   "array4D" => [0.245666 0.158608; 0.928513 0.76801…
#   "matrix"  => [0.680641 0.0316219; 0.935687 0.6919…
#   "scalar"  => [0.0540839, 0.349377, 0.646486, 0.59…
#   "array5D" => [0.709445 0.751825; 0.201938 0.73553…

close(file)
```

There are useful dispatches to load specific variables at specific steps as desired.
```julia
using ADIOS2
file = adios_open_serial("test.bp", mode_readRandomAccess)

# Read all variables at specific steps
adios_load(file, 5:10)

# Read a specific variable at all steps
adios_load(file, "vector")

# Read a specific variable at a specific step
adios_load(file, "step", 2)

# Read a specific variable at multiple steps
adios_load(file, "matrix", [1, 3, 5])

# Read multiple variables at specific steps
adios_load(file, ["scalar", "vector"], 0:2)
# Returns a dictionary: {"scalar" => [...], "vector" => [..., ...]}

# Use Regex to find and load variables that contian the patterns
data = adios_load(file, r"array.*", 0:2)
# julia> data = adios_load(file, r"array.*", 0:2)
# Dict{AbstractString, Any} with 3 entries:
#   "array3D" => [0.137995 0.157526; 0.198498 0.6809…
#   "array4D" => [0.245666 0.158608; 0.928513 0.7680…
#   "array5D" => [0.709445 0.751825; 0.201938 0.7355…

close(file)
```
