using ADIOS2

filename1 = "/gpfs/eschnetter/simulations/qc0/output-0000/qc0/qc0.it00000016.bp"
filename2 = "/gpfs/eschnetter/simulations/qc0-recover/output-0000/qc0-recover/qc0-recover.it00000016.bp"

adios = adios_init_serial()
io1 = declare_io(adios, "IO1")
io2 = declare_io(adios, "IO2")
engine1 = open(io1, filename1, mode_read)
engine2 = open(io2, filename2, mode_read)

variable_names = ["/data/16/meshes/admbase_lapse_rl00/admbase_alp",
                  "/data/16/meshes/admbase_lapse_rl01/admbase_alp",
                  "/data/16/meshes/admbase_lapse_rl02/admbase_alp",
                  "/data/16/meshes/admbase_lapse_rl03/admbase_alp",
                  "/data/16/meshes/admbase_lapse_rl04/admbase_alp",
                  "/data/16/meshes/admbase_lapse_rl05/admbase_alp"]

variables1 = [inquire_variable(io1, nm) for nm in variable_names]
variables2 = [inquire_variable(io2, nm) for nm in variable_names]

println("Variables:")
for (var1, var2) in zip(variables1, variables2)
    vars = (var1, var2)
    println("    name: ", name.(vars))
    println("    type: ", type.(vars))
    println("    shapeid: ", shapeid.(vars))
    println("    ndims: ", ndims.(vars))
    println("    shape: ", shape.(vars))
    println("    start: ", start.(vars))
    println("    count: ", count.(vars))
    println("    minimum: ", minimum.(vars))
    println("    maximum: ", maximum.(vars))

    T = type(var1)
    @assert type(var2) ≡ T
    size = count(var1)
    @assert count(var2) == size

    data1 = Array{T}(undef, Tuple(size))
    data2 = Array{T}(undef, Tuple(size))
    get(engine1, var1, data1)
    get(engine2, var2, data2)
    perform_gets(engine1)
    perform_gets(engine2)
    diff = maximum(abs.(data1 - data2))
    print("   maxabs: ", diff)
end
