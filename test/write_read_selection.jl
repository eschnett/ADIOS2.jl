# Test basic write and read using selections

if use_mpi
    if comm_rank == comm_root
        MPI.bcast(dirname, comm_root, comm)
    else
        const dirname = MPI.bcast(nothing, comm_root, comm)
    end
end

const filename_sel = "$dirname/test_nd_sel_2D.bp"

function _set_data_2D(T, comm_rank, step)
    data = ones(T, 10, 10)

    for j in 2:4
        for i in 2:4
            data[i, j] = comm_rank + step
        end
    end

    return data
end

@testset "File write nd global arrays" begin
    # Set up ADIOS
    if use_mpi
        adios = adios_init_mpi(comm)
    else
        adios = adios_init_serial()
    end
    @test adios isa Adios

    io = declare_io(adios, "io_writer")
    @test io isa AIO
    count = (10, 10)
    start = (0, comm_rank * 10)
    shape = (10, comm_size * 10)
    # open engine
    writer = open(io, filename_sel, mode_write)

    for step in 1:3
        begin_step(writer)

        for T in
            Type[Float32, Float64, Complex{Float32}, Complex{Float64}, Int8,
                 Int16, Int32, Int64, UInt8, UInt16, UInt32, UInt64]

            # define some nd array variables, 10x10 per MPI process
            var_T = step == 1 ?
                    define_variable(io, string(T), T, shape, start, count) :
                    inquire_variable(io, string(T))
            data_2D = _set_data_2D(T, comm_rank, step)
            put!(writer, var_T, data_2D) # deferred mode
        end

        end_step(writer)
    end
    close(writer)
    finalize(adios)
end

@testset "File read selection nd global arrays" begin
    # Set up ADIOS
    if use_mpi
        adios = adios_init_mpi(comm)
    else
        adios = adios_init_serial()
    end
    @test adios isa Adios

    io = declare_io(adios, "io_reader")
    @test io isa AIO

    sel_start = (2, comm_rank * 10 + 2)
    sel_count = (2, 2)

    # open engine
    reader = open(io, filename_sel, mode_read)

    for step in 1:3
        begin_step(reader)

        for T in
            Type[Float32, Float64, Complex{Float32}, Complex{Float64}, Int8,
                 Int16, Int32, Int64, UInt8, UInt16, UInt32, UInt64]

            # @TODO: 
            var_T = inquire_variable(io, string(T))
            @test var_T isa Variable
            set_selection(var_T, sel_start, sel_count)

            data_in = Array{T,2}(undef, 2, 2)
            get(reader, var_T, data_in, mode_sync)

            @test first(data_in) == comm_rank + step
            allsame(x) = all(y -> y == first(x), x)
            @test allsame(data_in)
        end

        end_step(reader)
    end
    close(reader)
    finalize(adios)
end
