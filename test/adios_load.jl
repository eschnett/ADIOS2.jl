@testset "adios_load with steps" begin
    tmp_dir = Base.Filesystem.mktempdir()

    bpName = "$tmp_dir/test.bp"

    # Define test data
    nn = 3
    scalar = rand()
    vector = rand(nn)
    matrix = rand(nn, nn)
    array3D = rand(nn, nn, nn)


    @testset "Write a test.bp file for test" begin

        # write test.bp data
        Nsteps = 10
        file = adios_open_serial(bpName, mode_write)
        for i in 0:(Nsteps - 1)
            begin_step(file.engine)

            adios_put!(file, "step", i)

            # root-level variables
            adios_put!(file, "scalar", scalar)
            adios_put!(file, "vector", vector)
            adios_put!(file, "matrix", matrix)
            adios_put!(file, "array3D", array3D)

            # with complex names
            adios_put!(file, "scalar_A", scalar)
            adios_put!(file, "scalar_B", scalar)
            adios_put!(file, "abc_scalar23", scalar)
            adios_put!(file, "scalar234", scalar)
            adios_put!(file, "deep/in/nested/groups/scalar", scalar)
            adios_put!(file, "another/deep/in/nested/groups/scalar", scalar)

            adios_perform_puts!(file)

            end_step(file.engine)
        end
        close(file)
    end

    @testset "Load all data at once" begin
        file = adios_open_serial(bpName, mode_readRandomAccess)

        Nsteps = steps(file.engine)

        # read test.bp data using adios_load
        all_data = adios_load(file)

        @test all_data["step"] == 0:(Nsteps - 1)
        @test all_data["scalar"] == fill(scalar, Nsteps)
        @test all_data["vector"] == repeat(vector, 1, Nsteps)
        @test all_data["matrix"] == repeat(matrix, 1, 1, Nsteps)
        @test all_data["array3D"] == repeat(array3D, 1, 1, 1, Nsteps)

        @test all_data["scalar_A"] == fill(scalar, Nsteps)
        @test all_data["scalar_B"] == fill(scalar, Nsteps)
        @test all_data["abc_scalar23"] == fill(scalar, Nsteps)
        @test all_data["scalar234"] == fill(scalar, Nsteps)
        @test all_data["deep/in/nested/groups/scalar"] == fill(scalar, Nsteps)
        @test all_data["another/deep/in/nested/groups/scalar"] ==
              fill(scalar, Nsteps)

        close(file)
    end

    @testset "Load all data at specific steps" begin
        file = adios_open_serial(bpName, mode_readRandomAccess)

        # single step
        target_step = 2

        all_data = adios_load(file,target_step)
        @test all_data["step"] == target_step
        @test all_data["scalar"] == scalar
        @test all_data["vector"] == vector
        @test all_data["matrix"] == matrix
        @test all_data["array3D"] == array3D

        # Multiple steps: read data from steps 2 to 5
        target_steps = 2:5
        all_data = adios_load(file,target_steps)

        @test all_data["step"] == target_steps
        @test all_data["scalar"] == fill(scalar, length(target_steps))
        @test all_data["vector"] == repeat(vector, 1, length(target_steps))
        @test all_data["matrix"] == repeat(matrix, 1, 1, length(target_steps))
        @test all_data["array3D"] == repeat(array3D, 1, 1, 1, length(target_steps))

        @test all_data["scalar_A"] == fill(scalar, length(target_steps))
        @test all_data["deep/in/nested/groups/scalar"] == fill(scalar, length(target_steps))

        close(file)
    end

    @testset "adios_load basic dispatches" begin
        file = adios_open_serial(bpName, mode_readRandomAccess)

        Nsteps = steps(file.engine)
        # single variable, all steps
        @test adios_load(file, "step") == 0:(Nsteps - 1)
        @test adios_load(file, "vector") == repeat(vector, 1, Nsteps)

        # single variable, specific step (@ step=3)
        @test adios_load(file, "step", 3) == 3
        @test adios_load(file, "scalar", 3) == scalar
        @test adios_load(file, "array3D", 3) == array3D

        # single varialbe, mulitiple steps
        @test adios_load(file, "step", [1, 3, 5]) == [1, 3, 5]
        @test adios_load(file, "step", [5, 3, 1]) == [5, 3, 1]
        @test adios_load(file, "step", 1:3) == 1:3
        @test adios_load(file, "matrix", [1, 3, 5]) == repeat(matrix, 1, 1, 3)

        # mulitiple variables, all steps
        @test adios_load(file, ["step", "vector"]) ==
              Dict("step" => 0:(Nsteps - 1),
                   "vector" => repeat(vector, 1, Nsteps))

        # multiple variables, specific step (@ step=3)
        @test adios_load(file, ["step", "vector"], 3) ==
              Dict("step" => 3, "vector" => vector)

        # multiple variables, multiple steps
        @test adios_load(file, ["step", "vector"], [1, 3, 5]) ==
              Dict("step" => [1, 3, 5], "vector" =>  repeat(vector, 1, 3) )

        close(file)
    end

    @testset "adios_load regex dispatches" begin
        file = adios_open_serial(bpName, mode_readRandomAccess)
        Nsteps = steps(file.engine)

        @test adios_load(file, r"step") == 0:(Nsteps - 1)

        @test adios_load(file, r"vector|matrix", [1, 3, 5]) ==
            Dict("vector" => repeat(vector, 1, 3),
                "matrix" => repeat(matrix, 1, 1, 3))

        @test adios_load(file, r"scalar.*[^\/]+") ==
              Dict("scalar_A" => fill(scalar, Nsteps),
                   "scalar_B" => fill(scalar, Nsteps),
                   "abc_scalar23" => fill(scalar, Nsteps),
                   "scalar234" => fill(scalar, Nsteps))

        @test adios_load(file, r"deep.*scalar") ==
              Dict("deep/in/nested/groups/scalar" => fill(scalar, Nsteps),
                   "another/deep/in/nested/groups/scalar" => fill(scalar, Nsteps))

        close(file)
    end

    @testset "adios_load with bpName directly" begin
        file = adios_open_serial(bpName, mode_readRandomAccess)

        @test adios_load(bpName) == adios_load(file)
        @test adios_load(bpName, "step") == adios_load(file, "step")
        @test adios_load(bpName, r"scalar") == adios_load(file, r"scalar")

        @test_throws ErrorException adios_load("non-existing-file.bp")
        @test_throws ErrorException adios_load("non-existing-file.bp", "step")

        close(file)
    end

    # clean up
    rm(bpName; force=true, recursive=true)
    rm(tmp_dir; force=true)
end