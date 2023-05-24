using ADIOS2
using Base.Filesystem
using Libdl
using MPI
using Printf
using Test

################################################################################
# Find ADIOS2 version

# There is no official way to find the ADIOS2 library version. Instead
# we test whether certain functions exist.
const ADIOS2_VERSION = let
    lib = dlopen(ADIOS2.libadios2_c)
    if dlsym(lib, :adios2_declare_io_order;
             throw_error=false) == Ptr{Cvoid}()
        v"2.8.0"
    else
        v"2.9.0"
    end
end

################################################################################

# Initialize MPI
const mpi_initialized = MPI.Initialized()
if !mpi_initialized
    MPI.Init()
end
const comm = MPI.COMM_WORLD
const comm_rank = MPI.Comm_rank(comm)
const comm_size = MPI.Comm_size(comm)
const comm_root = 0
const use_mpi = comm_size > 1

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

################################################################################

# Finalize MPI
const mpi_finalized = MPI.Finalized()
if mpi_initialized && !mpi_finalized
    MPI.Finalize()
end
