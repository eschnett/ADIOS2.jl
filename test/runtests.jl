using ADIOS2
using Base.Filesystem
using MPI
using Printf
using Test

################################################################################
# Find ADIOS2 version

# There is no official way to find the ADIOS2 library version. Instead
# we check the default engine type after opening a file.
# TODO: We don't support anyting below 2.10 anyway; we don't need this any more
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

println("MPI version: $(MPI.Get_version())")
println("MPI library version:")
println(MPI.Get_library_version())

# Initialize MPI
@assert !MPI.Finalized()
const mpi_initialized = MPI.Initialized()
if !mpi_initialized
    println("Initializing MPI")
    MPI.Init()
end
@assert MPI.Initialized()
const we_initialized_mpi = !mpi_initialized
const comm = MPI.COMM_WORLD
const comm_rank = MPI.Comm_rank(comm)
const comm_size = MPI.Comm_size(comm)
println("This is MPI process $comm_rank/$comm_size")
const comm_root = 0
const use_mpi = comm_size > 1
println("$(use_mpi ? "Enabling" : "Disabling") MPI tests")

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
const mpi_finalized = MPI.Finalized()
if we_initialized_mpi && !mpi_finalized
    println("Finalizing MPI")
    MPI.Finalize()
end
@assert MPI.Initialized()
@assert MPI.Finalized()
