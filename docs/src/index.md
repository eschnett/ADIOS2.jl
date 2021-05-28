# ADIOS2.jl

[ADIOS2.jl](https://github.com/eschnett/ADIOS2.jl) is a Julia
interface to the [ADIOS2](https://github.com/ornladios/ADIOS2), the
Adaptable Input Output System version 2.

## Basic API

### Types

```@docs
Error
AdiosType
Mode
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
define_attribute
define_attribute_array
define_variable_attribute
define_variable_attribute_array
inquire_attribute
inquire_variable_attribute
inquire_all_attributes
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
put!
perform_puts!
get
perform_gets
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
adios_define_attribute
adios_all_attribute_names
adios_attribute_data
adios_put!
adios_perform_puts!
adios_all_variable_names
IORef
isready(ioref::IORef)
fetch(ioref::IORef)
adios_get
adios_perform_gets
```
