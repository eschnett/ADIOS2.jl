#TODO using ADIOS2
using Base.Filesystem
using MPI
using Printf
using Test

#TODO ################################################################################
#TODO # Find ADIOS2 version
#TODO 
#TODO # There is no official way to find the ADIOS2 library version. Instead
#TODO # we check the default engine type after opening a file.
#TODO const ADIOS2_VERSION = let
#TODO     adios = adios_init_serial()
#TODO     io = declare_io(adios, "IO")
#TODO     filename = tempname()
#TODO     engine = open(io, filename, mode_write)
#TODO     etype = type(engine)
#TODO     close(engine)
#TODO     if etype == "BP4Writer"
#TODO         v"2.8.0"
#TODO     elseif etype == "BP5Writer"
#TODO         v"2.9.0"
#TODO     else
#TODO         @assert false
#TODO     end
#TODO end

################################################################################

# Initialize MPI
let
    const mpi_initialized = MPI.Initialized()
    if !mpi_initialized
        println("Initializing MPI")
        MPI.Init()
    end
    const comm = MPI.COMM_WORLD
    const comm_rank = MPI.Comm_rank(comm)
    const comm_size = MPI.Comm_size(comm)
    println("This is MPI process $comm_rank/$comm_size")
    const comm_root = 0
    const use_mpi = comm_size > 1
    println("$(use_mpi ? "Enabling" : "Disabling") MPI tests")
end

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

#TODO include("internal.jl")
#TODO include("basic.jl")
#TODO include("highlevel.jl")
#TODO include("write_read_selection.jl")
#TODO include("adios_load.jl")

################################################################################

# Finalize MPI
let
    const mpi_finalized = MPI.Finalized()
    if mpi_initialized && !mpi_finalized
        println("Finalizing MPI")
        MPI.Finalize()
    end
end
