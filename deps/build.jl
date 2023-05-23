# From https://github.com/JuliaIO/HDF5.jl/blob/master/deps/build.jl

using Libdl

const depsfile = joinpath(@__DIR__, "deps.jl")

libpath = get(ENV, "JULIA_ADIOS2_PATH", nothing)

# We avoid calling Libdl.find_library to avoid possible segfault when calling
# dlclose (#929).
# The only difference with Libdl.find_library is that we allow custom dlopen
# flags via the `flags` argument.
function find_library_alt(libnames, extrapaths=String[]; flags=RTLD_LAZY)
    for lib in libnames
        for path in extrapaths
            l = joinpath(path, lib)
            p = dlopen(l, flags; throw_error=false)
            if p !== nothing
                dlclose(p)
                return l
            end
        end
        p = dlopen(lib, flags; throw_error=false)
        if p !== nothing
            dlclose(p)
            return lib
        end
    end
    return ""
end

##

new_contents = if libpath === nothing
    # By default, use ADIOS2_jll
    """
    # This file is automatically generated
    # Do not edit
    using ADIOS2_jll
    check_deps() = nothing
    """
else
    @info "using system ADIOS2"

    libpaths = [libpath, joinpath(libpath, "lib"), joinpath(libpath, "lib64")]
    flags = RTLD_LAZY | RTLD_NODELETE  # RTLD_NODELETE may be needed to avoid segfault (#929)

    libadios2_c = find_library_alt(["libadios2_c"], libpaths; flags=flags)
    libadios2_c_mpi = find_library_alt(["libadios2_c_mpi"], libpaths;
                                       flags=flags)

    isempty(libadios2_c) && error("libadios2_c could not be found")

    isempty(libadios2_c_mpi) &&
        warning("libadios2_c_mpi could not be found, assuming ADIOS2 serial build")

    libadios2_c_size = filesize(dlpath(libadios2_c))

    """
    # This file is automatically generated
    # Do not edit
    function check_deps()
        if libadios2_c_size != filesize(Libdl.dlpath(libadios2_c))
            error("ADIOS2 library has changed, re-run Pkg.build(\\\"ADIOS2\\\")")
        end
    end
    $(:(const libadios2_c = $libadios2_c))
    $(:(const libadios2_c_mpi = $libadios2_c_mpi))
    $(:(const libadios2_c_size = $libadios2_c_size))
    """
end

if !isfile(depsfile) || new_contents != read(depsfile, String)
    # only write file if contents have changed to avoid triggering re-precompilation each build
    open(depsfile, "w") do io
        return print(io, new_contents)
    end
end
