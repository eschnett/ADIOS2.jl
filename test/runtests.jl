using ADIOS2
using Base.Filesystem
using MPI
using Printf
using Test

################################################################################
# Find ADIOS2 version

# There is no official way to find the ADIOS2 library version. Instead
# we check the default engine type after opening a file.
const ADIOS2_VERSION = let
    adios = adios_init_serial()
    io = declare_io(adios, "IO")
    filename = tempname()
    engine = open(io, filename, mode_write)
    etype = type(engine)
    close(engine)
    if etype == "BP4Writer"
        v"2.8.0"
    elseif etype == "BP5Writer"
        v"2.9.0"
    else
        @assert false
    end
end

################################################################################

# Initialize MPI
println("aaa.0")
let
    #=const=# mpi_initialized = MPI.Initialized()
    if !mpi_initialized
        println("Initializing MPI")
        MPI.Init()
    end
    global we_initialized_mpi = !mpi_initialized
    #=const=# comm = MPI.COMM_WORLD
    #=const=# comm_rank = MPI.Comm_rank(comm)
    #=const=# comm_size = MPI.Comm_size(comm)
    println("This is MPI process $comm_rank/$comm_size")
    #=const=# comm_root = 0
    #=const=# use_mpi = comm_size > 1
    println("$(use_mpi ? "Enabling" : "Disabling") MPI tests")
end
println("aaa.9")

################################################################################

"""
Convert an object to a string as the REPL would
"""
function showmime(obj)
    buf = IOBuffer()
    show(buf, MIME"text/plain"(), obj)
    return String(take!(buf))
end

################################################################################

include("internal.jl")
include("basic.jl")
include("highlevel.jl")
include("write_read_selection.jl")
include("adios_load.jl")

################################################################################

# Finalize MPI
println("zzz.0")
let
    println("zzz.1")
    #=const=# mpi_finalized = MPI.Finalized()
    println("zzz.2")
    if we_initialized_mpi && !mpi_finalized
        println("Finalizing MPI")
        MPI.Finalize()
    end
    println("zzz.3")
end
println("zzz.9")
