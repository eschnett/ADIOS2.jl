# ADIOS2.jl

[ADIOS2.jl](https://github.com/eschnett/ADIOS2.jl) is a Julia
interface to the [ADIOS2](https://github.com/ornladios/ADIOS2), the
Adaptable Input Output System version 2.

## Installation

```julia
julia>]
pkg> add ADIOS2
```

ADIOS2 binaries are downloaded by default using the `ADIOS2_jll` package

## Using a custom or system provided ADIOS2 library
Set the environment variable `JULIA_ADIOS2_PATH` to the top-level installation directory for ADIOS2, 
i.e. the `libadios2_c` and `libadios2_c_mpi` (if using MPI-enabled ADIOS2) libraries should be located 
under `$JULIA_ADIOS2_PATH/lib` or `$JULIA_ADIOS2_PATH/lib64`. Then run `import Pkg; Pkg.build("ADIOS2")`. 
This is preferred in high-performance computing (HPC) systems for system-wide installations for libraries built against
vendor MPI implementations. It is highly recommended that MPIPreferences points at the system MPI implementation used to build ADIOS2.

Example:

```sh
$ export JULIA_ADIOS2_PATH=/opt/adios2/2.8.3
```
Then in Julia, run:

```julia
pkg> build
```

## Basic API

### Types

```@docs
Error
AdiosType
Mode
StepMode
StepStatus
ShapeId
```

### Adios functions

```@docs
Adios
adios_init_mpi
adios_init_serial
declare_io
adios_finalize
```

### IO functions

```@docs
AIO
define_variable
inquire_variable
inquire_all_variables
inquire_group_variables
define_attribute
define_attribute_array
define_variable_attribute
define_variable_attribute_array
inquire_attribute
inquire_variable_attribute
inquire_all_attributes
inquire_group_attributes
inquire_subgroups
open
engine_type
get_engine
```

### Variable functions

```@docs
Variable
name(variable::Variable)
type(variable::Variable)
shapeid(variable::Variable)
ndims(variable::Variable)
shape(variable::Variable)
start(variable::Variable)
count(variable::Variable)
steps_start(variable::Variable)
steps(variable::Variable)
selection_size(variable::Variable)
minimum(variable::Variable)
maximum(variable::Variable)
```

### Attribute functions
```@docs
Attribute
name(attribute::Attribute)
type(attribute::Attribute)
is_value(attribute::Attribute)
size(attribute::Attribute)
data(attribute::Attribute)
```

### Engine functions

```@docs
Engine
name
type
openmode
begin_step
current_step
steps
put!
perform_puts!
get
perform_gets
end_step
flush(engine::Engine)
close(engine::Engine)
```

## High-Level API
```@docs
AdiosFile
adios_open_serial
adios_open_mpi
flush(file::AdiosFile)
close(file::AdiosFile)
adios_subgroup_names
adios_define_attribute
adios_all_attribute_names
adios_group_attribute_names
adios_attribute_data
adios_put!
adios_perform_puts!
adios_all_variable_names
adios_group_variable_names
IORef
isready(ioref::IORef)
fetch(ioref::IORef)
adios_get
adios_perform_gets
```
