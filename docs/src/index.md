# ADIOS2.jl

[ADIOS2.jl](https://github.com/eschnett/ADIOS2.jl) is a Julia
interface to the [ADIOS2](https://github.com/ornladios/ADIOS2), the
Adaptable Input Output System version 2.

## Types

```@docs
Error
Mode
ShapeId
```

## Adios functions

```@docs
Adios
init_mpi
init_serial
declare_io
afinalize
```

## IO functions

```@docs
AIO
define_variable
inquire_variable
inquire_all_variables
open
```

## Variable functions

```@docs
Variable
variable_name
variable_type
variable_type_string
variable_shapeid
variable_ndims
variable_shape
variable_start
variable_count
variable_steps_start
variable_steps
variable_selection_size
variable_min
variable_max
```

## Engine functions

```@docs
Engine
```
