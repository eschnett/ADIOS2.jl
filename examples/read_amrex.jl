using ADIOS2

filename = "/Users/eschnett/src/CarpetX/Cactus/amrex/amrex.bp"

adios = adios_init_serial()
io = declare_io(adios, "IO")
engine = open(io, filename, mode_read)

println("Variables:")
variables = inquire_all_variables(io)
for variable in variables
    vname = name(variable)
    vtype = type(variable)
    vshapeid = shapeid(variable)
    vndims = ndims(variable)
    vshape = shape(variable)
    vstart = start(variable)
    vcount = count(variable)
    vmin = minimum(variable)
    vmax = maximum(variable)
    println("    name: $name   type: $type")
    println("        shapeid: $shapeid   ndims: $ndims")
    println("        shape: $shape   start: $start   count: $count")
    println("        min: $varmin   max: $varmax")
end
