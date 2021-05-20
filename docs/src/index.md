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
adios_init_mpi
adios_init_serial
declare_io
adios_finalize
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
name
type
shapeid
ndims
shape
start
count
steps_start
steps
selection_size
minimum
maximum
```

## Engine functions

```@docs
Engine
```
