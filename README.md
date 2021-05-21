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
