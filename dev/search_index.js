var documenterSearchIndex = {"docs":
[{"location":"#ADIOS2.jl","page":"ADIOS2.jl","title":"ADIOS2.jl","text":"","category":"section"},{"location":"","page":"ADIOS2.jl","title":"ADIOS2.jl","text":"ADIOS2.jl is a Julia interface to the ADIOS2, the Adaptable Input Output System version 2.","category":"page"},{"location":"#Basic-API","page":"ADIOS2.jl","title":"Basic API","text":"","category":"section"},{"location":"#Types","page":"ADIOS2.jl","title":"Types","text":"","category":"section"},{"location":"","page":"ADIOS2.jl","title":"ADIOS2.jl","text":"Error\nAdiosType\nMode\nShapeId","category":"page"},{"location":"#ADIOS2.Error","page":"ADIOS2.jl","title":"ADIOS2.Error","text":"@enum Error begin\n    error_none\n    error_invalid_argument\n    error_system_error\n    error_runtime_error\n    error_exception\nend\n\nError return types for all ADIOS2 functions\n\nBased on the library C++ standardized exceptions. Each error will issue a more detailed description in the standard error output, stderr\n\n\n\n\n\n","category":"type"},{"location":"#ADIOS2.AdiosType","page":"ADIOS2.jl","title":"ADIOS2.AdiosType","text":"const AdiosType = Union{AbstractString,\n                        Float32,Float64,\n                        Complex{Float32},Complex{Float64},\n                        Int8,Int16,Int32,Int64,\n                        UInt8,UInt16,UInt32,UInt64}\n\nA Union of all scalar types supported in ADIOS files.\n\n\n\n\n\n","category":"type"},{"location":"#ADIOS2.Mode","page":"ADIOS2.jl","title":"ADIOS2.Mode","text":"@enum Mode begin\n    mode_undefined\n    mode_write\n    mode_read\n    mode_append\n    mode_deferred\n    mode_sync\nend\n\nMode specifies for various functions. write, read, append are used for file operations, deferred, sync are used for get and put operations.\n\n\n\n\n\n","category":"type"},{"location":"#ADIOS2.ShapeId","page":"ADIOS2.jl","title":"ADIOS2.ShapeId","text":"@enum ShapeId begin\n    shapeid_unknown\n    shapeid_global_value\n    shapeid_global_array\n    shapeid_joined_array\n    shapeid_local_value\n    shapeid_local_array\nend\n\n\n\n\n\n","category":"type"},{"location":"#Adios-functions","page":"ADIOS2.jl","title":"Adios functions","text":"","category":"section"},{"location":"","page":"ADIOS2.jl","title":"ADIOS2.jl","text":"Adios\nadios_init_mpi\nadios_init_serial\ndeclare_io\nadios_finalize","category":"page"},{"location":"#ADIOS2.Adios","page":"ADIOS2.jl","title":"ADIOS2.Adios","text":"mutable struct Adios\n\nHolds a C pointer adios2_adios *.\n\nThis value is finalized automatically. It can also be explicitly finalized by calling finalize(adios).\n\n\n\n\n\n","category":"type"},{"location":"#ADIOS2.adios_init_mpi","page":"ADIOS2.jl","title":"ADIOS2.adios_init_mpi","text":"adios = adios_init_mpi(comm::MPI.Comm)\nadios = adios_init_mpi(config_file::AbstractString, comm::MPI.Comm)\nadios::Union{Adios,Nothing}\n\nStarting point for MPI apps. Creates an ADIOS handler. MPI collective and it calls MPI_Comm_dup.\n\n\n\n\n\n","category":"function"},{"location":"#ADIOS2.adios_init_serial","page":"ADIOS2.jl","title":"ADIOS2.adios_init_serial","text":"adios = adios_init_serial()\nadios = adios_init_serial(config_file::AbstractString)\nadios::Union{Adios,Nothing}\n\nInitialize an Adios struct in a serial, non-MPI application. Doesn’t require a runtime config file.\n\nSee also the ADIOS2 documentation.\n\n\n\n\n\n","category":"function"},{"location":"#ADIOS2.declare_io","page":"ADIOS2.jl","title":"ADIOS2.declare_io","text":"io = declare_io(adios::Adios, name::AbstractString)\nio::Union{AIO,Nothing}\n\nDeclare a new IO handler.\n\nSee also the ADIOS2 documentation.\n\n\n\n\n\n","category":"function"},{"location":"#ADIOS2.adios_finalize","page":"ADIOS2.jl","title":"ADIOS2.adios_finalize","text":"err = adios_finalize(adios::Adios)\nerr::Error\n\nFinalize the ADIOS context adios. It is usually not necessary to call this function.\n\nInstead of calling this function, one can also call the finalizer via finalize(adios). This finalizer is also called automatically when the Adios object is garbage collected.\n\nSee also the ADIOS2 documentation\n\n\n\n\n\n","category":"function"},{"location":"#IO-functions","page":"ADIOS2.jl","title":"IO functions","text":"","category":"section"},{"location":"","page":"ADIOS2.jl","title":"ADIOS2.jl","text":"AIO\ndefine_variable\ninquire_variable\ninquire_all_variables\ninquire_group_variables\ndefine_attribute\ndefine_attribute_array\ndefine_variable_attribute\ndefine_variable_attribute_array\ninquire_attribute\ninquire_variable_attribute\ninquire_all_attributes\ninquire_group_attributes\ninquire_subgroups\nopen\nengine_type\nget_engine","category":"page"},{"location":"#ADIOS2.AIO","page":"ADIOS2.jl","title":"ADIOS2.AIO","text":"struct AIO\n\nHolds a C pointer adios2_io *.\n\n\n\n\n\n","category":"type"},{"location":"#ADIOS2.define_variable","page":"ADIOS2.jl","title":"ADIOS2.define_variable","text":"variable = define_variable(io::AIO, name::AbstractString, type::Type,\n                     shape::Union{Nothing,CartesianIndex}=nothing,\n                     start::Union{Nothing,CartesianIndex}=nothing,\n                     count::Union{Nothing,CartesianIndex}=nothing,\n                     constant_dims::Bool=false)\nvariable::Union{Nothing,Variable}\n\nDefine a variable within io.\n\nArguments\n\nio: handler that owns the variable\nname: unique variable identifier\ntype: primitive type\nndims: number of dimensions\nshape: global dimension\nstart: local offset\ncount: local dimension\nconstant_dims: true: shape, start, count won't change; false: shape, start, count will change after definition\n\n\n\n\n\n","category":"function"},{"location":"#ADIOS2.inquire_variable","page":"ADIOS2.jl","title":"ADIOS2.inquire_variable","text":"variable = inquire_variable(io::AIO, name::AbstractString)\nvariable::Union{Nothing,Variable}\n\nRetrieve a variable handler within current io handler.\n\nArguments\n\nio: handler to variable io owner\nname: unique variable identifier within io handler\n\n\n\n\n\n","category":"function"},{"location":"#ADIOS2.inquire_all_variables","page":"ADIOS2.jl","title":"ADIOS2.inquire_all_variables","text":"variables = inquire_all_variables(io::AIO)\nvariables::Union{Nothing,Vector{Variable}}\n\nReturns an array of variable handlers for all variable present in the io group.\n\nArguments\n\nio: handler to variables io owner\n\n\n\n\n\n","category":"function"},{"location":"#ADIOS2.inquire_group_variables","page":"ADIOS2.jl","title":"ADIOS2.inquire_group_variables","text":"vars = inquire_group_variables(io::AIO, full_prefix::AbstractString)\nvars::Vector{String}\n\nList all variables in the group full_prefix.\n\n\n\n\n\n","category":"function"},{"location":"#ADIOS2.define_attribute","page":"ADIOS2.jl","title":"ADIOS2.define_attribute","text":"attribute = define_attribute(io::AIO, name::AbstractString, value)\nattribute::Union{Nothing,Attribute}\n\nDefine an attribute value inside io.\n\n\n\n\n\n","category":"function"},{"location":"#ADIOS2.define_attribute_array","page":"ADIOS2.jl","title":"ADIOS2.define_attribute_array","text":"attribute = define_attribute_array(io::AIO, name::AbstractString,\n                                   values::AbstractVector)\nattribute::Union{Nothing,Attribute}\n\nDefine an attribute array inside io.\n\n\n\n\n\n","category":"function"},{"location":"#ADIOS2.define_variable_attribute","page":"ADIOS2.jl","title":"ADIOS2.define_variable_attribute","text":"attribute = define_variable_attribute(io::AIO, name::AbstractString, value,\n                                      variable_name::AbstractString,\n                                      separator::AbstractString=\"/\")\nattribute::Union{Nothing,Attribute}\n\nDefine an attribute single value associated to an existing variable by its name.\n\n\n\n\n\n","category":"function"},{"location":"#ADIOS2.define_variable_attribute_array","page":"ADIOS2.jl","title":"ADIOS2.define_variable_attribute_array","text":"attribute = define_variable_attribute_array(io::AIO, name::AbstractString,\n                                            values::AbstractVector,\n                                            variable_name::AbstractString,\n                                            separator::AbstractString=\"/\")\nattribute::Union{Nothing,Attribute}\n\nDefine an attribute array associated to an existing variable by its name.\n\n\n\n\n\n","category":"function"},{"location":"#ADIOS2.inquire_attribute","page":"ADIOS2.jl","title":"ADIOS2.inquire_attribute","text":"attribute = inquire_attribute(io::AIO, name::AbstractString)\nattribute::Union{Nothing,Attribute}\n\nReturn a handler to a previously defined attribute by name.\n\n\n\n\n\n","category":"function"},{"location":"#ADIOS2.inquire_variable_attribute","page":"ADIOS2.jl","title":"ADIOS2.inquire_variable_attribute","text":"attribute = inquire_variable_attribute(io::AIO, name::AbstractString,\n                                       variable_name::AbstractString,\n                                       separator::AbstractString=\"/\")\nattribute::Union{Nothing,Attribute}\n\nReturn a handler to a previously defined attribute by name.\n\n\n\n\n\n","category":"function"},{"location":"#ADIOS2.inquire_all_attributes","page":"ADIOS2.jl","title":"ADIOS2.inquire_all_attributes","text":"attributes = inquire_all_attributes(io::AIO)\nattributes::Union{Nothing,Vector{Attribute}}\n\nReturn an array of attribute handlers for all attribute present in the io group.\n\n\n\n\n\n","category":"function"},{"location":"#ADIOS2.inquire_group_attributes","page":"ADIOS2.jl","title":"ADIOS2.inquire_group_attributes","text":"vars = inquire_group_attributes(io::AIO, full_prefix::AbstractString)\nvars::Vector{String}\n\nList all attributes in the group full_prefix.\n\n\n\n\n\n","category":"function"},{"location":"#ADIOS2.inquire_subgroups","page":"ADIOS2.jl","title":"ADIOS2.inquire_subgroups","text":"groups = inquire_subgroups(io::AIO, full_prefix::AbstractString)\ngroups::Vector{String}\n\nList all subgroups in the group full_prefix.\n\n\n\n\n\n","category":"function"},{"location":"#Base.open","page":"ADIOS2.jl","title":"Base.open","text":"engine = open(io::AIO, name::AbstractString, mode::Mode)\nengine::Union{Nothing,Engine}\n\nOpen an Engine to start heavy-weight input/output operations.\n\nIn MPI version reuses the communicator from adios_init_mpi. MPI Collective function as it calls MPI_Comm_dup.\n\nArguments\n\nio: engine owner\nname: unique engine identifier\nmode: mode_write, mode_read, mode_append (not yet supported)\n\n\n\n\n\n","category":"function"},{"location":"#ADIOS2.engine_type","page":"ADIOS2.jl","title":"ADIOS2.engine_type","text":"type = engine_type(io::AIO)\ntype::Union{Nothing,String}\n\nReturn engine type string.\n\n\n\n\n\n","category":"function"},{"location":"#ADIOS2.get_engine","page":"ADIOS2.jl","title":"ADIOS2.get_engine","text":"engine = get_engine(io::AIO, name::AbstractString)\nengine::Union{Nothing,Engine}\n\n\n\n\n\n","category":"function"},{"location":"#Variable-functions","page":"ADIOS2.jl","title":"Variable functions","text":"","category":"section"},{"location":"","page":"ADIOS2.jl","title":"ADIOS2.jl","text":"Variable\nname(variable::Variable)\ntype(variable::Variable)\nshapeid(variable::Variable)\nndims(variable::Variable)\nshape(variable::Variable)\nstart(variable::Variable)\ncount(variable::Variable)\nsteps_start(variable::Variable)\nsteps(variable::Variable)\nselection_size(variable::Variable)\nminimum(variable::Variable)\nmaximum(variable::Variable)","category":"page"},{"location":"#ADIOS2.Variable","page":"ADIOS2.jl","title":"ADIOS2.Variable","text":"struct Variable\n\nHolds a C pointer adios2_variable *.\n\n\n\n\n\n","category":"type"},{"location":"#ADIOS2.name-Tuple{Variable}","page":"ADIOS2.jl","title":"ADIOS2.name","text":"var_name = name(variable::Variable)\nvar_name::Union{Nothing,String}\n\nRetrieve variable name.\n\n\n\n\n\n","category":"method"},{"location":"#ADIOS2.type-Tuple{Variable}","page":"ADIOS2.jl","title":"ADIOS2.type","text":"var_type = type(variable::Variable)\nvar_type::Union{Nothing,Type}\n\nRetrieve variable type.\n\n\n\n\n\n","category":"method"},{"location":"#ADIOS2.shapeid-Tuple{Variable}","page":"ADIOS2.jl","title":"ADIOS2.shapeid","text":"var_shapeid = shapeid(variable::Variable)\nvar_shapeid::Union{Nothing,ShapeId}\n\nRetrieve variable shapeid.\n\n\n\n\n\n","category":"method"},{"location":"#Base.ndims-Tuple{Variable}","page":"ADIOS2.jl","title":"Base.ndims","text":"var_ndims = ndims(variable::Variable)\nvar_ndims::Union{Nothing,Int}\n\nRetrieve current variable number of dimensions.\n\n\n\n\n\n","category":"method"},{"location":"#ADIOS2.shape-Tuple{Variable}","page":"ADIOS2.jl","title":"ADIOS2.shape","text":"var_shape = shape(variable::Variable)\nvar_shape::Union{Nothing,CartesianIndex}\n\nRetrieve current variable shape.\n\n\n\n\n\n","category":"method"},{"location":"#ADIOS2.start-Tuple{Variable}","page":"ADIOS2.jl","title":"ADIOS2.start","text":"var_start = start(variable::Variable)\nvar_start::Union{Nothing,CartesianIndex}\n\nRetrieve current variable start.\n\n\n\n\n\n","category":"method"},{"location":"#Base.count-Tuple{Variable}","page":"ADIOS2.jl","title":"Base.count","text":"var_count = count(variable::Variable)\nvar_count::Union{Nothing,CartesianIndex}\n\nRetrieve current variable count.\n\n\n\n\n\n","category":"method"},{"location":"#ADIOS2.steps_start-Tuple{Variable}","page":"ADIOS2.jl","title":"ADIOS2.steps_start","text":"var_steps_start = steps_start(variable::Variable)\nvar_steps_start::Union{Nothing,Int}\n\nRead API, get available steps start from available steps count (e.g. in a file for a variable).\n\nThis returns the absolute first available step, don't use with adios2_set_step_selection as inputs are relative, use 0 instead.\n\n\n\n\n\n","category":"method"},{"location":"#ADIOS2.steps-Tuple{Variable}","page":"ADIOS2.jl","title":"ADIOS2.steps","text":"var_steps = steps(variable::Variable)\nvar_steps::Union{Nothing,Int}\n\nRead API, get available steps count from available steps count (e.g. in a file for a variable). Not necessarily contiguous.\n\n\n\n\n\n","category":"method"},{"location":"#ADIOS2.selection_size-Tuple{Variable}","page":"ADIOS2.jl","title":"ADIOS2.selection_size","text":"var_selection_size = selection_size(variable::Variable)\nvar_selection_size::Union{Nothing,Int}\n\nReturn the minimum required allocation (in number of elements of a certain type, not bytes) for the current selection.\n\n\n\n\n\n","category":"method"},{"location":"#Base.minimum-Tuple{Variable}","page":"ADIOS2.jl","title":"Base.minimum","text":"var_min = minimum(variable::Variable)\nvar_min::Union{Nothing,T}\n\nRead mode only: return the absolute minimum for variable.\n\n\n\n\n\n","category":"method"},{"location":"#Base.maximum-Tuple{Variable}","page":"ADIOS2.jl","title":"Base.maximum","text":"var_max = maximum(variable::Variable)\nvar_max::Union{Nothing,T}\n\nRead mode only: return the absolute maximum for variable.\n\n\n\n\n\n","category":"method"},{"location":"#Attribute-functions","page":"ADIOS2.jl","title":"Attribute functions","text":"","category":"section"},{"location":"","page":"ADIOS2.jl","title":"ADIOS2.jl","text":"Attribute\nname(attribute::Attribute)\ntype(attribute::Attribute)\nis_value(attribute::Attribute)\nsize(attribute::Attribute)\ndata(attribute::Attribute)","category":"page"},{"location":"#ADIOS2.Attribute","page":"ADIOS2.jl","title":"ADIOS2.Attribute","text":"struct Attribute\n\nHolds a C pointer adios2_attribute *.\n\n\n\n\n\n","category":"type"},{"location":"#ADIOS2.name-Tuple{Attribute}","page":"ADIOS2.jl","title":"ADIOS2.name","text":"attr_name = name(attribute::Attribute)\nattr_name::Union{Nothing,String}\n\nRetrieve attribute name.\n\n\n\n\n\n","category":"method"},{"location":"#ADIOS2.type-Tuple{Attribute}","page":"ADIOS2.jl","title":"ADIOS2.type","text":"attr_type = type(attribute::Attribute)\nattr_type::Union{Nothing,Type}\n\nRetrieve attribute type.\n\n\n\n\n\n","category":"method"},{"location":"#ADIOS2.is_value-Tuple{Attribute}","page":"ADIOS2.jl","title":"ADIOS2.is_value","text":"attr_is_value = is_value(attribute::Attribute)\nattr_is_value::Union{Nothing,Bool}\n\nRetrieve attribute type.\n\n\n\n\n\n","category":"method"},{"location":"#Base.size-Tuple{Attribute}","page":"ADIOS2.jl","title":"Base.size","text":"attr_size = size(attribute::Attribute)\nattr_size::Union{Nothing,Int}\n\nRetrieve attribute size.\n\n\n\n\n\n","category":"method"},{"location":"#ADIOS2.data-Tuple{Attribute}","page":"ADIOS2.jl","title":"ADIOS2.data","text":"attr_data = data(attribute::Attribute)\nattr_data::Union{Nothing,AdiosType,Vector{<:AdiosType}}\n\nRetrieve attribute Data.\n\n\n\n\n\n","category":"method"},{"location":"#Engine-functions","page":"ADIOS2.jl","title":"Engine functions","text":"","category":"section"},{"location":"","page":"ADIOS2.jl","title":"ADIOS2.jl","text":"Engine\nput!\nperform_puts!\nget\nperform_gets\nflush(engine::Engine)\nclose(engine::Engine)","category":"page"},{"location":"#ADIOS2.Engine","page":"ADIOS2.jl","title":"ADIOS2.Engine","text":"struct Engine\n\nHolds a C pointer adios2_engine *.\n\n\n\n\n\n","category":"type"},{"location":"#Base.put!","page":"ADIOS2.jl","title":"Base.put!","text":"err = Base.put!(engine::Engine, variable::Variable,\n                data::Union{Ref,Array,Ptr}, launch::Mode=mode_deferred)\nerr = Base.put!(engine::Engine, variable::Variable, data::AdiosType,\n                launch::Mode=mode_deferred)\nerr::Error\n\nSchedule writing a variable to file. Call perform_puts! to perform the actual write operations.\n\nThe reference/array/pointer target must not be modified before perform_puts! is called. It is most efficenty to schedule multiple put! operations before calling perform_puts!.\n\n\n\n\n\n","category":"function"},{"location":"#ADIOS2.perform_puts!","page":"ADIOS2.jl","title":"ADIOS2.perform_puts!","text":"perform_puts!(engine::Engine)\n\nExecute all currently scheduled write operations.\n\n\n\n\n\n","category":"function"},{"location":"#Base.get","page":"ADIOS2.jl","title":"Base.get","text":"err = Base.get(engine::Engine, variable::Variable,\n               data::Union{Ref,Array,Ptr}, launch::Mode=mode_deferred)\nerr::Error\n\nSchedule reading a variable from file into the provided buffer data. Call perform_gets to perform the actual read operations.\n\nThe reference/array/pointer target must not be modified before perform_gets is called. It is most efficenty to schedule multiple get operations before calling perform_gets.\n\n\n\n\n\n","category":"function"},{"location":"#ADIOS2.perform_gets","page":"ADIOS2.jl","title":"ADIOS2.perform_gets","text":"perform_gets(engine::Engine)\n\nExecute all currently scheduled read operations.\n\n\n\n\n\n","category":"function"},{"location":"#Base.flush-Tuple{Engine}","page":"ADIOS2.jl","title":"Base.flush","text":"flush(engine::Engine)\n\nFlush all buffered data to file. Call this after perform_puts! to ensure data are actually written to file.\n\n\n\n\n\n","category":"method"},{"location":"#Base.close-Tuple{Engine}","page":"ADIOS2.jl","title":"Base.close","text":"close(engine::Engine)\n\nClose a file. This implicitly also flushed all buffered data.\n\n\n\n\n\n","category":"method"},{"location":"#High-Level-API","page":"ADIOS2.jl","title":"High-Level API","text":"","category":"section"},{"location":"","page":"ADIOS2.jl","title":"ADIOS2.jl","text":"AdiosFile\nadios_open_serial\nadios_open_mpi\nflush(file::AdiosFile)\nclose(file::AdiosFile)\nadios_subgroup_names\nadios_define_attribute\nadios_all_attribute_names\nadios_group_attribute_names\nadios_attribute_data\nadios_put!\nadios_perform_puts!\nadios_all_variable_names\nadios_group_variable_names\nIORef\nisready(ioref::IORef)\nfetch(ioref::IORef)\nadios_get\nadios_perform_gets","category":"page"},{"location":"#ADIOS2.AdiosFile","page":"ADIOS2.jl","title":"ADIOS2.AdiosFile","text":"struct AdiosFile\n\nContext for the high-level API for an ADIOS file\n\n\n\n\n\n","category":"type"},{"location":"#ADIOS2.adios_open_serial","page":"ADIOS2.jl","title":"ADIOS2.adios_open_serial","text":"adios = adios_open_serial(filename::AbstractString, mode::Mode)\nadios::AdiosFile\n\nOpen an ADIOS file. Use mode = mode_write for writing and mode = mode_read for reading.\n\n\n\n\n\n","category":"function"},{"location":"#ADIOS2.adios_open_mpi","page":"ADIOS2.jl","title":"ADIOS2.adios_open_mpi","text":"adios = adios_open_mpi(comm::MPI.Comm, filename::AbstractString, mode::Mode)\nadios::AdiosFile\n\nOpen an ADIOS file for parallel I/O. Use mode = mode_write for writing and mode = mode_read for reading.\n\n\n\n\n\n","category":"function"},{"location":"#Base.flush-Tuple{AdiosFile}","page":"ADIOS2.jl","title":"Base.flush","text":"flush(file::AdiosFile)\n\nFlush an ADIOS file. When writing, flushing or closing a file is necesssary to ensure that data are actually written to the file.\n\n\n\n\n\n","category":"method"},{"location":"#Base.close-Tuple{AdiosFile}","page":"ADIOS2.jl","title":"Base.close","text":"close(file::AdiosFile)\n\nClose an ADIOS file. When writing, flushing or closing a file is necesssary to ensure that data are actually written to the file.\n\n\n\n\n\n","category":"method"},{"location":"#ADIOS2.adios_subgroup_names","page":"ADIOS2.jl","title":"ADIOS2.adios_subgroup_names","text":"groups = adios_subgroup_names(file::AdiosFile, groupname::AbstractString)\nvars::Vector{String}\n\nList (non-recursively) all subgroups in the group groupname in the file.\n\n\n\n\n\n","category":"function"},{"location":"#ADIOS2.adios_define_attribute","page":"ADIOS2.jl","title":"ADIOS2.adios_define_attribute","text":"adiosdefineattribute(file::AdiosFile, name::AbstractString,                           value::AdiosType)\n\nWrite a scalar attribute.\n\n\n\n\n\nadios_define_attribute(file::AdiosFile, name::AbstractString,\n                       value::AbstractArray{<:AdiosType})\n\nWrite an array-valued attribute.\n\n\n\n\n\nadios_define_attribute(file::AdiosFile, path::AbstractString,\n                       name::AbstractString, value::AdiosType)\n\nWrite a scalar attribute into the path path in the file.\n\n\n\n\n\nadios_define_attribute(file::AdiosFile, path::AbstractString,\n                       name::AbstractString,\n                       value::AbstractArray{<:AdiosType})\n\nWrite an array-valued attribute into the path path in the file.\n\n\n\n\n\n","category":"function"},{"location":"#ADIOS2.adios_all_attribute_names","page":"ADIOS2.jl","title":"ADIOS2.adios_all_attribute_names","text":"attrs = adios_all_attribute_names(file::AdiosFile)\nattrs::Vector{String}\n\nList (recursively) all attributes in the file.\n\n\n\n\n\n","category":"function"},{"location":"#ADIOS2.adios_group_attribute_names","page":"ADIOS2.jl","title":"ADIOS2.adios_group_attribute_names","text":"vars = adios_group_attribute_names(file::AdiosFile, groupname::AbstractString)\nvars::Vector{String}\n\nList (non-recursively) all attributes in the group groupname in the file.\n\n\n\n\n\n","category":"function"},{"location":"#ADIOS2.adios_attribute_data","page":"ADIOS2.jl","title":"ADIOS2.adios_attribute_data","text":"attr_data = adios_attribute_data(file::AdiosFile, name::AbstractString)\nattr_data::Union{Nothing,AdiosType}\n\nRead an attribute from a file. Return nothing if the attribute is not found.\n\n\n\n\n\nattr_data =  adios_attribute_data(file::AdiosFile, path::AbstractString,\n                                  name::AbstractString)\nattr_data::Union{Nothing,AdiosType}\n\nRead an attribute from a file in path path. Return nothing if the attribute is not found.\n\n\n\n\n\n","category":"function"},{"location":"#ADIOS2.adios_put!","page":"ADIOS2.jl","title":"ADIOS2.adios_put!","text":"adios_put!(file::AdiosFile, name::AbstractString, scalar::AdiosType)\n\nSchedule writing a scalar variable to a file.\n\nThe variable is not written until adios_perform_puts! is called and the file is flushed or closed.\n\n\n\n\n\nadios_put!(file::AdiosFile, name::AbstractString,\n           array::AbstractArray{<:AdiosType}; make_copy::Bool=false)\n\nSchedule writing an array-valued variable to a file.\n\nmake_copy determines whether to make a copy of the array, which is expensive for large arrays. When no copy is made, then the array must not be modified before adios_perform_puts! is called.\n\nThe variable is not written until adios_perform_puts! is called and the file is flushed or closed.\n\n\n\n\n\n","category":"function"},{"location":"#ADIOS2.adios_perform_puts!","page":"ADIOS2.jl","title":"ADIOS2.adios_perform_puts!","text":"adios_perform_puts!(file::AdiosFile)\n\nExecute all scheduled adios_put! operations.\n\nThe data might not be in the file yet; they might be buffered. Call adios_flush or adios_close to ensure all data are written to file.\n\n\n\n\n\n","category":"function"},{"location":"#ADIOS2.adios_all_variable_names","page":"ADIOS2.jl","title":"ADIOS2.adios_all_variable_names","text":"vars = adios_all_variable_names(file::AdiosFile)\nvars::Vector{String}\n\nList (recursively) all variables in the file.\n\n\n\n\n\n","category":"function"},{"location":"#ADIOS2.adios_group_variable_names","page":"ADIOS2.jl","title":"ADIOS2.adios_group_variable_names","text":"vars = adios_group_variable_names(file::AdiosFile, groupname::AbstractString)\nvars::Vector{String}\n\nList (non-recursively) all variables in the group groupname in the file.\n\n\n\n\n\n","category":"function"},{"location":"#ADIOS2.IORef","page":"ADIOS2.jl","title":"ADIOS2.IORef","text":"mutable struct IORef{T,D}\n\nA reference to the value of a variable that has been scheduled to be read from disk. This value cannot be accessed bofre the read operations have actually been executed.\n\nUse fetch(ioref::IORef) to access the value. fetch will trigger the actual reading from file if necessary. It is most efficient to schedule multiple read operations at once.\n\nUse adios_perform_gets to trigger reading all currently scheduled variables.\n\n\n\n\n\n","category":"type"},{"location":"#Base.isready-Tuple{IORef}","page":"ADIOS2.jl","title":"Base.isready","text":"isready(ioref::IORef)::Bool\n\nCheck whether an IORef has already been read from file.\n\n\n\n\n\n","category":"method"},{"location":"#Base.fetch-Tuple{IORef}","page":"ADIOS2.jl","title":"Base.fetch","text":"value = fetch(ioref::IORef{T,D}) where {T,D}\nvalue::Array{T,D}\n\nAccess an IORef. If necessary, the variable is read from file and then cached. (Each IORef is read at most once.)\n\nScalars are handled as zero-dimensional arrays. To access the value of a zero-dimensional array, write array[] (i.e. use array indexing, but without any indices).\n\n\n\n\n\n","category":"method"},{"location":"#ADIOS2.adios_get","page":"ADIOS2.jl","title":"ADIOS2.adios_get","text":"ioref = adios_get(file::AdiosFile, name::AbstractString)\nioref::Union{Nothing,IORef}\n\nSchedule reading a variable from a file.\n\nThe variable is not read until adios_perform_gets is called. This happens automatically when the IORef is accessed (via fetch). It is most efficient to first schedule multiple variables for reading, and then executing the reads together.\n\n\n\n\n\n","category":"function"},{"location":"#ADIOS2.adios_perform_gets","page":"ADIOS2.jl","title":"ADIOS2.adios_perform_gets","text":"adios_perform_gets(file::AdiosFile)\n\nExecute all currently scheduled read opertions. This makes all pending IORefs ready.\n\n\n\n\n\n","category":"function"}]
}
