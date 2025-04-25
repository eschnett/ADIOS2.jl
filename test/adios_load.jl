@testset "adios_load " begin
    tmp_dir = Base.Filesystem.mktempdir()

    nn = 3

    # write test.bp data
    N_steps = 10
    file = adios_open_serial("$tmp_dir/test.bp", mode_write)
    for i in 0:(N_steps - 1)
        begin_step(file.engine)

        adios_put!(file, "step", i)

        # group1 (all members filled with value 1)
        adios_put!(file, "group1/scalar", 1)
        adios_put!(file, "group1/vector", fill(1, nn))
        adios_put!(file, "group1/matrix", fill(1, (nn, nn)))
        adios_put!(file, "group1/Nd_array", fill(1, (nn, nn, nn)))

        # group2 (all members filled with value 2)
        adios_put!(file, "group2/scalar", 2)
        adios_put!(file, "group2/vector", fill(2, nn))
        adios_put!(file, "group2/matrix", fill(2, (nn, nn)))
        adios_put!(file, "group2/Nd_array", fill(2, (nn, nn, nn)))

        # with complex names
        adios_put!(file, "scalar_A", 1)
        adios_put!(file, "scalar_B", 1)
        adios_put!(file, "abc_scalar_123", 1)
        adios_put!(file, "scalar_1234", 1)
        adios_put!(file, "deep/in/nested/groups/scalar", 1)
        adios_put!(file, "another/deep/in/nested/groups/scalar", 1)

        adios_perform_puts!(file)

        end_step(file.engine)
    end
    close(file)

    # read test.bp data using adios_load
    file = adios_open_serial("$tmp_dir/test.bp", mode_readRandomAccess)

    @testset "Load all data at once" begin
        all_data = adios_load(file)

        @test all_data["step"] == 0:(N_steps - 1)
        @test all_data["group1/scalar"] == fill(1, N_steps)
        @test all_data["group1/vector"] == fill(1, (nn, N_steps))
        @test all_data["group1/matrix"] == fill(1, (nn, nn, N_steps))
        @test all_data["group1/Nd_array"] == fill(1, (nn, nn, nn, N_steps))

        @test all_data["group2/scalar"] == fill(2, N_steps)
        @test all_data["group2/vector"] == fill(2, (nn, N_steps))
        @test all_data["group2/matrix"] == fill(2, (nn, nn, N_steps))
        @test all_data["group2/Nd_array"] == fill(2, (nn, nn, nn, N_steps))

        @test all_data["scalar_A"] == fill(1, N_steps)
        @test all_data["scalar_B"] == fill(1, N_steps)
        @test all_data["abc_scalar_123"] == fill(1, N_steps)
        @test all_data["scalar_1234"] == fill(1, N_steps)
        @test all_data["deep/in/nested/groups/scalar"] == fill(1, N_steps)
        @test all_data["another/deep/in/nested/groups/scalar"] ==
              fill(1, N_steps)
    end

    @testset "adios_load basic dispatches" begin
        # single variable, all steps
        @test adios_load(file, "step") == 0:(N_steps - 1)
        @test adios_load(file, "group2/vector") == fill(2, (nn, N_steps))

        # single variable, specific step (@ step=3)
        @test adios_load(file, "step", 3) == 3
        @test adios_load(file, "group1/scalar", 3) == 1
        @test adios_load(file, "group2/matrix", 3) == fill(2, (nn, nn))
        @test adios_load(file, "group2/Nd_array", 3) == fill(2, (nn, nn, nn))

        # single varialbe, mulitiple steps
        @test adios_load(file, "step", [1, 3, 5]) == [1, 3, 5]
        @test adios_load(file, "step", [5, 3, 1]) == [5, 3, 1]
        @test adios_load(file, "step", 1:3) == 1:3
        @test adios_load(file, "group2/matrix", [1, 3, 5]) ==
              fill(2, (nn, nn, 3))

        # mulitiple variables, all steps
        @test adios_load(file, ["step", "group1/vector"]) ==
              Dict("step" => 0:(N_steps - 1),
                   "group1/vector" => fill(1, (nn, N_steps)))

        # multiple variables, specific step (@ step=3)
        @test adios_load(file, ["step", "group1/vector"], 3) ==
              Dict("step" => 3, "group1/vector" => fill(1, (nn)))

        # multiple variables, multiple steps
        @test adios_load(file, ["step", "group1/vector"], [1, 3, 5]) ==
              Dict("step" => [1, 3, 5], "group1/vector" => fill(1, (nn, 3)))
    end

    @testset "adios_load regex dispatches" begin
        @test adios_load(file, r"step") == 0:(N_steps - 1)
        @test adios_load(file, r"^gro.*scalar") ==
              Dict("group1/scalar" => fill(1, N_steps),
                   "group2/scalar" => fill(2, N_steps))

        @test adios_load(file, r"vector|matrix", [1, 3, 5]) ==
              Dict("group1/vector" => fill(1, (nn, 3)),
                   "group2/vector" => fill(2, (nn, 3)),
                   "group1/matrix" => fill(1, (nn, nn, 3)),
                   "group2/matrix" => fill(2, (nn, nn, 3)))

        @test adios_load(file, r"scalar.*[^\/]+") ==
              Dict("scalar_A" => fill(1, N_steps),
                   "scalar_B" => fill(1, N_steps),
                   "abc_scalar_123" => fill(1, N_steps),
                   "scalar_1234" => fill(1, N_steps))

        @test adios_load(file, r"deep.*scalar") ==
              Dict("deep/in/nested/groups/scalar" => fill(1, N_steps),
                   "another/deep/in/nested/groups/scalar" => fill(1, N_steps))

        @test adios_load(file, r"group1.*") ==
              Dict("group1/scalar" => fill(1, N_steps),
                   "group1/vector" => fill(1, (nn, N_steps)),
                   "group1/matrix" => fill(1, (nn, nn, N_steps)),
                   "group1/Nd_array" => fill(1, (nn, nn, nn, N_steps)))

        @test adios_load(file, r"group1.*") ==
              Dict("group1/scalar" => fill(1, N_steps),
                   "group1/vector" => fill(1, (nn, N_steps)),
                   "group1/matrix" => fill(1, (nn, nn, N_steps)),
                   "group1/Nd_array" => fill(1, (nn, nn, nn, N_steps)))

        @test adios_load(file, r"deep.*scalar") ==
              Dict("deep/in/nested/groups/scalar" => fill(1, N_steps),
                   "another/deep/in/nested/groups/scalar" => fill(1, N_steps))
    end

    # clean up
    close(file)
    rm("$tmp_dir/test.bp"; force=true, recursive=true)
    rm(tmp_dir; force=true)
end
