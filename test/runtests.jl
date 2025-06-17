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

#TODO # Initialize MPI
println("aaa.0")
#TODO let
#TODO     global #=const=# mpi_initialized = MPI.Initialized()
#TODO     if !mpi_initialized
#TODO         println("Initializing MPI")
#TODO         MPI.Init()
#TODO     end
#TODO     #=const=# comm = MPI.COMM_WORLD
#TODO     #=const=# comm_rank = MPI.Comm_rank(comm)
#TODO     #=const=# comm_size = MPI.Comm_size(comm)
#TODO     println("This is MPI process $comm_rank/$comm_size")
#TODO     #=const=# comm_root = 0
#TODO     #=const=# use_mpi = comm_size > 1
#TODO     println("$(use_mpi ? "Enabling" : "Disabling") MPI tests")
#TODO end
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

#TODO include("internal.jl")
#TODO include("basic.jl")
#TODO include("highlevel.jl")
#TODO include("write_read_selection.jl")
#TODO include("adios_load.jl")

################################################################################

# Finalize MPI
println("zzz.0")
#TODO let
#TODO     println("zzz.1")
#TODO     #=const=# mpi_finalized = MPI.Finalized()
#TODO     println("zzz.2")
#TODO     if mpi_initialized && !mpi_finalized
#TODO         println("Finalizing MPI")
#TODO         MPI.Finalize()
#TODO     end
#TODO     println("zzz.3")
#TODO end
println("zzz.9")
