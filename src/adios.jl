# Adios functions

export Adios
"""
    mutable struct Adios

Holds a C pointer `adios2_adios *`.

This value is finalized automatically. It can also be explicitly
finalized by calling `finalize(adios)`.
"""
mutable struct Adios
    ptr::Ptr{Cvoid}
    Adios(ptr) = finalizer(adios_finalize, new(ptr))
end
Adios() = Adios(C_NULL)

export adios_init_mpi
"""
    adios = adios_init_mpi(MPI.Comm)
    adios::Union{Adios,Nothing}

Starting point for MPI apps. Creates an ADIOS handler. MPI collective
and it calls `MPI_Comm_dup`.
"""
function adios_init_mpi(comm::MPI.Comm)
    ptr = ccall((:adios2_init_mpi, libadios2_c_mpi), Ptr{Cvoid},
                (MPI.MPI_Comm,), comm)
    return ptr == C_NULL ? nothing : Adios(ptr)
end

export adios_init_serial
"""
    adios = adios_init_serial()
    adios::Union{Adios,Nothing}

Initialize an Adios struct in a serial, non-MPI application. Doesn’t
require a runtime config file.

See also the [ADIOS2
documentation](https://adios2.readthedocs.io/en/latest/api_full/api_full.html#_CPPv418adios2_init_serialv).
"""
function adios_init_serial()
    ptr = ccall((:adios2_init_serial, libadios2_c), Ptr{Cvoid}, ())
    return ptr == C_NULL ? nothing : Adios(ptr)
end

export declare_io
"""
    io = declare_io(adios::Adios, name::AbstractString)
    io::Union{AIO,Nothing}

Declare a new IO handler.

See also the [ADIOS2
documentation](https://adios2.readthedocs.io/en/latest/api_full/api_full.html#_CPPv417adios2_declare_ioP12adios2_adiosPKc).
"""
function declare_io(adios::Adios, name::AbstractString)
    ptr = ccall((:adios2_declare_io, libadios2_c), Ptr{Cvoid},
                (Ptr{Cvoid}, Cstring), adios.ptr, name)
    return ptr == C_NULL ? nothing : AIO(ptr)
end

export adios_finalize
"""
    err = adios_finalize(adios::Adios)
    err::Error

Finalize the ADIOS context `adios`. It is usually not necessary to
call this function.

Instead of calling this function, one can also call the finalizer via
`finalize(adios)`. This finalizer is also called automatically when
the Adios object is garbage collected.

See also the [ADIOS2
documentation](https://adios2.readthedocs.io/en/latest/api_full/api_full.html#_CPPv415adios2_finalizeP12adios2_adios)
"""
function adios_finalize(adios::Adios)
    adios.ptr == C_NULL && return error_none
    err = ccall((:adios2_finalize, libadios2_c), Cint, (Ptr{Cvoid},), adios.ptr)
    adios.ptr = C_NULL
    return Error(err)
end
