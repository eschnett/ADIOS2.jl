module ADIOS2

using ADIOS2_jll
using MPI

### Helpers

const Maybe{T} = Union{Nothing,T}
maybe(::Nothing, other) = other
maybe(x, other) = x

function free(ptr::Ptr)
    @static Sys.iswindows() ? Libc.free(ptr) :
            ccall((:free, libadios2_c), Cvoid, (Ptr{Cvoid},), ptr)
end

include("types.jl")
include("adios.jl")
include("io.jl")
include("variable.jl")
include("attribute.jl")
include("engine.jl")

end
