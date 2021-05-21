using ADIOS2
using Base.Filesystem
using MPI
using Printf
using Test

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

@testset "Internal tests" begin
    for jtype in ADIOS2.julia_types
        @test ADIOS2.julia_type(ADIOS2.adios_type(jtype)) ≡ jtype
    end
    for atype in ADIOS2.adios_types
        @test ADIOS2.adios_type(ADIOS2.julia_type(atype)) ≡ atype
    end
end

const rankstr = @sprintf "%06d" comm_rank

if comm_rank == comm_root
    const dirname = Filesystem.mktempdir(; cleanup=true)
end
if use_mpi
    if comm_rank == comm_root
        MPI.bcast(dirname, comm_root, comm)
    else
        const dirname = MPI.bcast(nothing, comm_root, comm)
    end
end
const filename = "$dirname/test.bp"

@testset "File tests" for pass in 1:3
    # Set up ADIOS
    if use_mpi
        adios = adios_init_mpi(comm)
    else
        adios = adios_init_serial()
    end
    @test adios isa Adios

    io = declare_io(adios, "IO")
    @test io isa AIO

    # Define some variables
    scalar = 247.0
    svar = define_variable(io, "scalar.p$rankstr", scalar)
    @test svar isa Variable

    array = Float64[10i + j for i in 1:2, j in 1:3]
    avar = define_variable(io, "array.p$rankstr", array)
    @test avar isa Variable

    garray = Float64[10i + (3 * comm_rank + j) for i in 1:2, j in 1:3]
    gsh = CartesianIndex((1, comm_size) .* size(garray))
    gst = CartesianIndex((0, comm_rank) .* size(garray))
    gco = CartesianIndex(size(garray))
    gvar = define_variable(io, "garray", eltype(garray), gsh, gst, gco)

    var1 = inquire_variable(io, "array.p$rankstr")
    @test var1 isa Variable
    var2 = inquire_variable(io, "not a variable.p$rankstr")
    @test var2 isa Nothing

    allvars = inquire_all_variables(io)
    @test Set(allvars) == Set([svar, avar, gvar])

    @test name(svar) == "scalar.p$rankstr"
    @test name(avar) == "array.p$rankstr"
    @test name(gvar) == "garray"
    @test type(svar) == typeof(scalar)
    @test type(avar) == eltype(array)
    @test type(gvar) == eltype(garray)
    @test shapeid(svar) == shapeid_global_value
    @test shapeid(avar) == shapeid_local_array
    @test shapeid(gvar) == shapeid_global_array
    @test ndims(svar) == 0
    @test ndims(avar) == 0      # avar is alocal
    @test ndims(gvar) == 2
    @test shape(svar) == CartesianIndex()
    @test shape(avar) == CartesianIndex() # avar is local
    @test shape(gvar) == gsh
    @test start(svar) == CartesianIndex()
    @test start(avar) == CartesianIndex() # avar is local
    @test start(gvar) == gst
    @test count(svar) == CartesianIndex()
    # This segfaults; see
    # <https://github.com/ornladios/ADIOS2/issues/2711>
    # @test_broken count(avar) == CartesianIndex(2, 3)
    @test count(gvar) == gco

    etype = engine_type(io)
    @test etype == "File"

    if pass == 1
        attr = define_attribute(io, "attribute.p$rankstr", 247.0f0)
        @test attr isa Attribute
        attrarr = define_attribute_array(io, "attribute_array.p$rankstr",
                                         Float32[3, 1, 4, 1, 6])
        @test attrarr isa Attribute
        varattr = define_variable_attribute(io, "variable_attribute.p$rankstr",
                                            247, name(svar))
        @test varattr isa Attribute
        varattrarr = define_variable_attribute_array(io,
                                                     "variable_attribute_array.p$rankstr",
                                                     [3, 1, 4, 1, 6],
                                                     name(svar))
        @test varattrarr isa Attribute

        attr0 = inquire_attribute(io, "no such attribute")
        @test attr0 isa Nothing
        attr1 = inquire_attribute(io, "attribute.p$rankstr")
        @test attr1 isa Attribute
        attrs = inquire_all_attributes(io)
        @test Set(attrs) == Set([attr, attrarr, varattr, varattrarr])

        # Don't read/write any variables

    elseif pass == 2
        attr = define_attribute(io, "attribute.p$rankstr", 247.0f0)
        @test attr isa Attribute
        attrarr = define_attribute_array(io, "attribute_array.p$rankstr",
                                         Float32[3, 1, 4, 1, 6])
        @test attrarr isa Attribute
        varattr = define_variable_attribute(io, "variable_attribute.p$rankstr",
                                            247, name(svar))
        @test varattr isa Attribute
        varattrarr = define_variable_attribute_array(io,
                                                     "variable_attribute_array.p$rankstr",
                                                     [3, 1, 4, 1, 6],
                                                     name(svar))
        @test varattrarr isa Attribute

        attr0 = inquire_attribute(io, "no such attribute")
        @test attr0 isa Nothing
        attr1 = inquire_attribute(io, "attribute.p$rankstr")
        @test attr1 isa Attribute
        attrs = inquire_all_attributes(io)
        @test length(attrs) ==
              comm_size * length([attr, attrarr, varattr, varattrarr])
        @test Set(attrs) ⊇ Set([attr, attrarr, varattr, varattrarr])

        # Write a file
        engine = open(io, filename, mode_write)

        err = put!(engine, svar, scalar)
        @test err ≡ error_none
        err = put!(engine, avar, array)
        @test err ≡ error_none
        err = perform_puts!(engine)
        @test err ≡ error_none

        # @test minimum(svar) == scalar
        # @test minimum(avar) == 11
        # @test minimum(gvar) == 11
        # @test maximum(svar) == scalar
        # @test maximum(avar) == 23
        # @test maximum(gvar) == 23

        err = close(engine)
        @test err ≡ error_none

    elseif pass == 3

        # Read the file
        engine = open(io, filename, mode_read)

        attr = inquire_attribute(io, "attribute.p$rankstr")
        @test attr isa Attribute
        attrarr = inquire_attribute(io, "attribute_array.p$rankstr")
        @test attrarr isa Attribute
        varattr = inquire_variable_attribute(io, "variable_attribute.p$rankstr",
                                             name(svar))
        @test varattr isa Attribute
        varattrarr = inquire_variable_attribute(io,
                                                "variable_attribute_array.p$rankstr",
                                                name(svar))
        @test varattrarr isa Attribute

        attr0 = inquire_attribute(io, "no such attribute")
        @test attr0 isa Nothing
        attr1 = inquire_attribute(io, "attribute.p$rankstr")
        @test attr1 isa Attribute
        attrs = inquire_all_attributes(io)
        @test Set(attrs) == Set([attr, attrarr, varattr, varattrarr])

        # Read variables

        scalar′ = Ref(scalar + 1)
        err = get(engine, svar, scalar′)
        @test err ≡ error_none
        array′ = array .+ 1
        err = get(engine, avar, array′)
        @test err ≡ error_none
        err = perform_gets(engine)
        @test err ≡ error_none

        @test scalar′[] == scalar
        @test array′ == array

        @test_broken minimum(svar) == scalar
        @test_broken minimum(avar) == 11
        @test_broken minimum(gvar) == 11
        @test maximum(svar) == scalar
        @test maximum(avar) == 23
        @test_broken maximum(gvar) == 23

        err = close(engine)
        @test err ≡ error_none
    end

    # Test various versions of finalizing the Adios object
    if pass == 1
        err = adios_finalize(adios)
        @test err ≡ error_none
        err = adios_finalize(adios)
        @test err ≡ error_none
    elseif pass == 2
        finalize(adios)
        finalize(adios)
    elseif pass == 3
        adios = nothing
    end
    # Call gc to test finalizing the Adios object
    GC.gc(true)
end
# Call gc to test finalizing the Adios object
GC.gc(true)

################################################################################

# Finalize MPI
const mpi_finalized = MPI.Finalized()
if mpi_initialized && !mpi_finalized
    MPI.Finalize()
end
