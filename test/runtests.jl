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

################################################################################

# Basic API tests

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

@testset "File tests: $passname" for (pass, passname) in
                                     enumerate(["metadata", "write", "read"])

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
    value = 247.0
    vvar = define_variable(io, "value.p$rankstr", typeof(value))
    @test vvar isa Variable

    lvalue = 42.0
    lvar = define_variable(io, "lvalue.p$rankstr", lvalue)
    @test lvar isa Variable

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
    @test Set(allvars) == Set([vvar, lvar, avar, gvar])

    @test name(vvar) == "value.p$rankstr"
    @test name(lvar) == "lvalue.p$rankstr"
    @test name(avar) == "array.p$rankstr"
    @test name(gvar) == "garray"
    @test type(vvar) == typeof(value)
    @test type(lvar) == typeof(lvalue)
    @test type(avar) == eltype(array)
    @test type(gvar) == eltype(garray)
    @test shapeid(vvar) == shapeid_global_value
    @test shapeid(lvar) == shapeid_local_value
    @test shapeid(avar) == shapeid_local_array
    @test shapeid(gvar) == shapeid_global_array
    @test ndims(vvar) == 0
    @test ndims(lvar) == 0
    @test ndims(avar) == 2
    @test ndims(gvar) == 2
    @test shape(vvar) == CartesianIndex()
    @test shape(lvar) ≡ nothing
    @test shape(avar) ≡ nothing
    @test shape(gvar) == gsh
    @test start(vvar) == CartesianIndex()
    @test start(lvar) == nothing
    @test start(avar) ≡ nothing
    @test start(gvar) == gst
    @test count(vvar) == CartesianIndex()
    @test count(lvar) == CartesianIndex()
    @test count(avar) == CartesianIndex(2, 3)
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
                                            247, name(vvar))
        @test varattr isa Attribute
        varattrarr = define_variable_attribute_array(io,
                                                     "variable_attribute_array.p$rankstr",
                                                     [3, 1, 4, 1, 6],
                                                     name(vvar))
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
                                            247, name(vvar))
        @test varattr isa Attribute
        varattrarr = define_variable_attribute_array(io,
                                                     "variable_attribute_array.p$rankstr",
                                                     [3, 1, 4, 1, 6],
                                                     name(vvar))
        @test varattrarr isa Attribute

        attr0 = inquire_attribute(io, "no such attribute")
        @test attr0 isa Nothing
        attr1 = inquire_attribute(io, "attribute.p$rankstr")
        @test attr1 isa Attribute
        attrs = inquire_all_attributes(io)
        # After writing, only the locally written attributes are
        # visible
        @test Set(attrs) == Set([attr, attrarr, varattr, varattrarr])

        # Write a file
        engine = open(io, filename, mode_write)

        err = put!(engine, vvar, value)
        @test err ≡ error_none
        err = put!(engine, lvar, lvalue)
        @test err ≡ error_none
        err = put!(engine, avar, array)
        @test err ≡ error_none
        err = put!(engine, gvar, garray)
        @test err ≡ error_none
        err = perform_puts!(engine)
        @test err ≡ error_none

        # @test minimum(vvar) == value
        # @test minimum(avar) == 11
        # @test minimum(gvar) == 11
        # @test maximum(vvar) == value
        # @test maximum(avar) == 23
        # @test maximum(gvar) == 23

        err = close(engine)
        @test err ≡ error_none
        # run(`/Users/eschnett/src/CarpetX/Cactus/view/bin/bpls -aD $filename`)

    elseif pass == 3

        # Read the file

        engine = open(io, filename, mode_read)

        attr = inquire_attribute(io, "attribute.p$rankstr")
        @test attr isa Attribute
        attrarr = inquire_attribute(io, "attribute_array.p$rankstr")
        @test attrarr isa Attribute
        varattr = inquire_variable_attribute(io, "variable_attribute.p$rankstr",
                                             name(vvar))
        @test varattr isa Attribute
        varattrarr = inquire_variable_attribute(io,
                                                "variable_attribute_array.p$rankstr",
                                                name(vvar))
        @test varattrarr isa Attribute

        # Read attributes

        attr0 = inquire_attribute(io, "no such attribute")
        @test attr0 isa Nothing
        attr1 = inquire_attribute(io, "attribute.p$rankstr")
        @test attr1 isa Attribute
        attrs = inquire_all_attributes(io)
        # After reading, all attributes are visible
        @test length(attrs) ==
              comm_size * length([attr, attrarr, varattr, varattrarr])
        @test Set(attrs) ⊇ Set([attr, attrarr, varattr, varattrarr])

        @test name(attr1) == "attribute.p$rankstr"
        @test name(attr) == "attribute.p$rankstr"
        @test name(attrarr) == "attribute_array.p$rankstr"
        @test name(varattr) == name(vvar) * "/variable_attribute.p$rankstr"
        @test name(varattrarr) ==
              name(vvar) * "/variable_attribute_array.p$rankstr"

        @test type(attr1) ≡ Float32
        @test type(attr) ≡ Float32
        @test type(attrarr) ≡ Float32
        @test type(varattr) ≡ Int
        @test type(varattrarr) ≡ Int

        @test is_value(attr1) ≡ true
        @test is_value(attr) ≡ true
        @test is_value(attrarr) ≡ false
        @test is_value(varattr) ≡ true
        @test is_value(varattrarr) ≡ false

        @test size(attr1) == 1
        @test size(attr) == 1
        @test size(attrarr) == 5
        @test size(varattr) == 1
        @test size(varattrarr) == 5

        @test typeof(data(attr1)) == Vector{Float32}
        @test typeof(data(attr)) == Vector{Float32}
        @test typeof(data(attrarr)) == Vector{Float32}
        @test typeof(data(varattr)) == Vector{Int}
        @test typeof(data(varattrarr)) == Vector{Int}

        @test data(attr1) == [247.0f0]
        @test data(attr) == [247.0f0]
        @test data(attrarr) == Float32[3, 1, 4, 1, 6]
        @test data(varattr) == [247]
        @test data(varattrarr) == [3, 1, 4, 1, 6]

        # Read variables

        vvar′ = inquire_variable(io, "value.p$rankstr")
        @test name(vvar′) == "value.p$rankstr"
        @test type(vvar′) == typeof(value)
        @test shapeid(vvar′) == shapeid_global_value
        @test ndims(vvar′) == 0
        @test shape(vvar′) == CartesianIndex() # should be nothing
        @test start(vvar′) == CartesianIndex() # should be nothing
        @test count(vvar′) == CartesianIndex()

        lvar′ = inquire_variable(io, "lvalue.p$rankstr")
        @test name(lvar′) == "lvalue.p$rankstr"
        @test type(lvar′) == typeof(lvalue)
        @test shapeid(lvar′) == shapeid_local_value
        @test ndims(lvar′) == 0
        @test shape(lvar′) ≡ nothing
        @test start(lvar′) ≡ nothing
        @test count(lvar′) == CartesianIndex()

        avar′ = inquire_variable(io, "array.p$rankstr")
        @test name(avar′) == "array.p$rankstr"
        @test type(avar′) == eltype(array)
        @test shapeid(avar′) == shapeid_local_array
        @test ndims(avar′) == ndims(array)
        @test shape(avar′) ≡ nothing
        @test start(avar′) ≡ nothing
        @test count(avar′) == CartesianIndex(size(array))

        gvar′ = inquire_variable(io, "garray")
        @test name(gvar′) == "garray"
        @test type(gvar′) == eltype(garray)
        @test shapeid(gvar′) == shapeid_global_array
        @test ndims(gvar′) == ndims(garray)
        @test shape(gvar′) == CartesianIndex((1, comm_size) .* size(garray))
        @test start(gvar′) == CartesianIndex((0, comm_rank) .* size(garray))
        @test count(gvar′) == CartesianIndex(size(garray))

        value′ = Ref(value + 1)
        err = get(engine, vvar, value′)
        @test err ≡ error_none
        lvalue′ = Ref(lvalue + 1)
        err = get(engine, lvar, lvalue′)
        @test err ≡ error_none
        array′ = array .+ 1
        err = get(engine, avar, array′)
        @test err ≡ error_none
        garray′ = garray .+ 1
        err = get(engine, gvar, garray′)
        @test err ≡ error_none
        err = perform_gets(engine)
        @test err ≡ error_none

        @test value′[] == value
        @test lvalue′[] == lvalue
        @test array′ == array
        @test garray′ == garray

        @test_broken minimum(vvar) == value
        @test minimum(vvar) == 0 # don't want this
        @test_broken minimum(lvar) == lvalue
        @test minimum(lvar) == 0 # don't want this
        @test_broken minimum(avar) == 11
        @test minimum(avar) == 0 # don't want this
        @test_broken minimum(gvar) == 11
        @test minimum(gvar) == 0 # don't want this
        @test maximum(vvar) == value
        @test maximum(lvar) == lvalue
        @test maximum(avar) == 23
        @test maximum(gvar) == 20 + comm_size * 3

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

# High-level tests

makearray(D, val) = fill(val, ntuple(d -> 1, D))

if comm_rank == 0
    const dirname2 = Filesystem.mktempdir(; cleanup=true)
    const filename2 = "$dirname2/test.bp"

    @testset "High-level write tests " begin
        file = adios_open_serial(filename2, mode_write)

        adios_define_attribute(file, "a1", float(π))
        adios_define_attribute(file, "a2", [float(π)])
        adios_define_attribute(file, "a3", [float(π), 0])

        adios_put!(file, "v1", float(ℯ))
        adios_put!(file, "v2", makearray(0, float(ℯ)))
        adios_put!(file, "v3", makearray(1, float(ℯ)))
        adios_put!(file, "v4", makearray(2, float(ℯ)))
        adios_put!(file, "v5", makearray(3, float(ℯ)))
        adios_put!(file, "v6", makearray(4, float(ℯ)))
        adios_put!(file, "v7", makearray(5, float(ℯ)))

        @test shapeid(inquire_variable(file.io, "v1")) == shapeid_local_value
        @test shapeid(inquire_variable(file.io, "v2")) == shapeid_local_value # 0-dim arrays are values
        @test shapeid(inquire_variable(file.io, "v3")) == shapeid_local_array
        @test shapeid(inquire_variable(file.io, "v4")) == shapeid_local_array
        @test shapeid(inquire_variable(file.io, "v5")) == shapeid_local_array
        @test shapeid(inquire_variable(file.io, "v6")) == shapeid_local_array
        @test shapeid(inquire_variable(file.io, "v7")) == shapeid_local_array

        adios_define_attribute(file, "v4/a4", float(π))
        adios_define_attribute(file, "v5", "a5", [float(π)])
        adios_define_attribute(file, "v6", "a6", [float(π), 0])

        adios_perform_puts!(file)
        close(file)
    end
    # run(`/Users/eschnett/src/CarpetX/Cactus/view/bin/bpls -aD $filename2`)

    @testset "High-level read tests " begin
        file = adios_open_serial(filename2, mode_read)
        @test Set(adios_all_attribute_names(file)) ==
              Set(["a1", "a2", "a3", "v4/a4", "v5/a5", "v6/a6"])

        @test adios_attribute_data(file, "a1") == [float(π)]
        @test adios_attribute_data(file, "a2") == [float(π)]
        @test adios_attribute_data(file, "a3") == [float(π), 0]
        @test adios_attribute_data(file, "v4", "a4") == [float(π)]
        @test adios_attribute_data(file, "v5/a5") == [float(π)]
        @test adios_attribute_data(file, "v6", "a6") == [float(π), 0]

        @test Set(adios_all_variable_names(file)) ==
              Set(["v1", "v2", "v3", "v4", "v5", "v6", "v7"])

        @test_broken shapeid(inquire_variable(file.io, "v1")) ==
                     shapeid_local_value
        @test shapeid(inquire_variable(file.io, "v1")) == shapeid_global_array # don't want this
        @test_broken shapeid(inquire_variable(file.io, "v2")) ==
                     shapeid_local_value
        @test shapeid(inquire_variable(file.io, "v2")) == shapeid_global_array # don't want this
        @test shapeid(inquire_variable(file.io, "v3")) == shapeid_local_array
        @test shapeid(inquire_variable(file.io, "v4")) == shapeid_local_array
        @test shapeid(inquire_variable(file.io, "v5")) == shapeid_local_array
        @test shapeid(inquire_variable(file.io, "v6")) == shapeid_local_array
        @test shapeid(inquire_variable(file.io, "v7")) == shapeid_local_array

        @test_broken ndims(inquire_variable(file.io, "v1")) == 0
        @test ndims(inquire_variable(file.io, "v1")) == 1 # don't want this
        @test_broken ndims(inquire_variable(file.io, "v2")) == 0
        @test ndims(inquire_variable(file.io, "v2")) == 1 # don't want this
        @test ndims(inquire_variable(file.io, "v3")) == 1
        @test ndims(inquire_variable(file.io, "v4")) == 2
        @test ndims(inquire_variable(file.io, "v5")) == 3
        @test ndims(inquire_variable(file.io, "v6")) == 4
        @test ndims(inquire_variable(file.io, "v7")) == 5

        @test_broken shape(inquire_variable(file.io, "v1")) ≡ nothing
        @test shape(inquire_variable(file.io, "v1")) == CartesianIndex(1) # don't want this
        @test_broken shape(inquire_variable(file.io, "v2")) ≡ nothing
        @test shape(inquire_variable(file.io, "v2")) == CartesianIndex(1) # don't want this
        @test shape(inquire_variable(file.io, "v3")) ≡ nothing
        @test shape(inquire_variable(file.io, "v4")) ≡ nothing
        @test shape(inquire_variable(file.io, "v5")) ≡ nothing
        @test shape(inquire_variable(file.io, "v6")) ≡ nothing
        @test shape(inquire_variable(file.io, "v7")) ≡ nothing

        @test_broken start(inquire_variable(file.io, "v1")) ≡ nothing
        @test start(inquire_variable(file.io, "v1")) == CartesianIndex(0) # don't want this
        @test_broken start(inquire_variable(file.io, "v2")) ≡ nothing
        @test start(inquire_variable(file.io, "v2")) == CartesianIndex(0) # don't want this
        @test start(inquire_variable(file.io, "v3")) ≡ nothing
        @test start(inquire_variable(file.io, "v4")) ≡ nothing
        @test start(inquire_variable(file.io, "v5")) ≡ nothing
        @test start(inquire_variable(file.io, "v6")) ≡ nothing
        @test start(inquire_variable(file.io, "v7")) ≡ nothing

        @test_broken count(inquire_variable(file.io, "v1")) ≡ nothing
        @test count(inquire_variable(file.io, "v1")) == CartesianIndex(1) # don't want this
        @test_broken count(inquire_variable(file.io, "v2")) == CartesianIndex()
        @test count(inquire_variable(file.io, "v2")) == CartesianIndex(1) # don't want this
        @test count(inquire_variable(file.io, "v3")) == CartesianIndex(1)
        @test count(inquire_variable(file.io, "v4")) == CartesianIndex(1, 1)
        @test count(inquire_variable(file.io, "v5")) == CartesianIndex(1, 1, 1)
        @test count(inquire_variable(file.io, "v6")) ==
              CartesianIndex(1, 1, 1, 1)
        @test count(inquire_variable(file.io, "v7")) ==
              CartesianIndex(1, 1, 1, 1, 1)

        v1 = adios_get(file, "v1")
        @test !isready(v1)
        @test_broken fetch(v1) == fill(float(ℯ))
        @test fetch(v1) == fill(float(ℯ), 1) # don't want this
        @test isready(v1)
        v2 = adios_get(file, "v2")
        v3 = adios_get(file, "v3")
        v4 = adios_get(file, "v4")
        @test !isready(v2)
        @test_broken fetch(v2) == makearray(0, float(ℯ))
        @test fetch(v2) == makearray(1, float(ℯ)) # don't want this
        @test fetch(v3) == makearray(1, float(ℯ))
        @test fetch(v4) == makearray(2, float(ℯ))
        @test isready(v2)
        v5 = adios_get(file, "v5")
        v6 = adios_get(file, "v6")
        v7 = adios_get(file, "v7")
        @test !isready(v5)
        adios_perform_gets(file)
        @test isready(v5)
        @test fetch(v5) == makearray(3, float(ℯ))
        @test fetch(v6) == makearray(4, float(ℯ))
        @test fetch(v7) == makearray(5, float(ℯ))
        close(file)
    end
end

################################################################################

# Finalize MPI
const mpi_finalized = MPI.Finalized()
if mpi_initialized && !mpi_finalized
    MPI.Finalize()
end
