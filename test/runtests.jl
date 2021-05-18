using ADIOS2
using Base.Filesystem
using Test

@testset "Internal tests" begin
    for jtype in ADIOS2.julia_types
        @test ADIOS2.julia_type(ADIOS2.adios_type(jtype)) ≡ jtype
    end
    for atype in ADIOS2.adios_types
        @test ADIOS2.adios_type(ADIOS2.julia_type(atype)) ≡ atype
    end
end

dirname = Filesystem.mktempdir()
filename = "$dirname/test.bp"

@testset "File tests" for pass in 1:3
    # Set up ADIOS
    adios = init_serial()
    @test adios isa Adios

    io = declare_io(adios, "IO")
    @test io isa AIO

    # Define some variables
    scalar = 247.0
    svar = define_variable(io, "scalar", scalar)
    @test svar isa Variable

    array = Float64[10i + j for i in 1:2, j in 1:3]
    avar = define_variable(io, "array", array)
    @test avar isa Variable

    var1 = inquire_variable(io, "array")
    @test var1 isa Variable
    var2 = inquire_variable(io, "not a variable")
    @test var2 isa Nothing

    allvars = inquire_all_variables(io)
    @test Set(allvars) == Set([svar, avar])

    if pass == 1

        # do nothing

    elseif pass == 2

        # Write a file
        engine = open(io, filename, mode_write)

        err = put!(engine, svar, scalar)
        @test err ≡ error_none
        err = put!(engine, avar, array)
        @test err ≡ error_none
        err = perform_puts!(engine)
        @test err ≡ error_none

        err = close(engine)
        @test err ≡ error_none

    elseif pass == 3

        # Read the file
        engine = open(io, filename, mode_read)

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

        err = close(engine)
        @test err ≡ error_none
    end

    # Test various versions of finalizing the Adios object
    if pass == 1
        err = afinalize(adios)
        @test err ≡ error_none
        err = afinalize(adios)
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
