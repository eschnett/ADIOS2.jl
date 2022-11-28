module ADIOS2

using MPI
using Libdl

const depsfile = joinpath(@__DIR__, "..", "deps", "deps.jl")
if isfile(depsfile)
    include(depsfile)
else
    error("ADIOS2 is not properly installed. Please run Pkg.build(\"ADIOS2\") ",
          "and restart Julia.")
end

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

include("highlevel.jl")

function __init__()
    check_deps()
    return
end

end
