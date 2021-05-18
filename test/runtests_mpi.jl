using MPI

function _init()
    MPI.Init()

    comm_rank = MPI.Comm_rank(MPI.COMM_WORLD)
    comm_size = MPI.Comm_size(MPI.COMM_WORLD)

    if comm_rank == 0
        println("MPI_LIBRARY_VERSION_STRING:")
        println(MPI.MPI_LIBRARY_VERSION_STRING)
        println("Comm size: $comm_size")
    end
end
_init()

include("runtests.jl")

function _finalize()
    comm_rank = MPI.Comm_rank(MPI.COMM_WORLD)
    comm_size = MPI.Comm_size(MPI.COMM_WORLD)

    comm_rank == 0 && println("Calling MPI.Finalize...")
    MPI.Finalize()
    return comm_rank == 0 && println("Done.")
end
_finalize()
