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
        adios_put!(file, "v3", makearray(1, float(ℯ)))
        adios_put!(file, "v4", makearray(2, float(ℯ)))
        adios_put!(file, "v5", makearray(3, float(ℯ)))
        adios_put!(file, "g1/v6", makearray(4, float(ℯ)))
        adios_put!(file, "g1/g2/v7", makearray(5, float(ℯ)))

        @test shapeid(inquire_variable(file.io, "v1")) == shapeid_local_value
        @test shapeid(inquire_variable(file.io, "v3")) == shapeid_local_array
        @test shapeid(inquire_variable(file.io, "v4")) == shapeid_local_array
        @test shapeid(inquire_variable(file.io, "v5")) == shapeid_local_array
        @test shapeid(inquire_variable(file.io, "g1/v6")) == shapeid_local_array
        @test shapeid(inquire_variable(file.io, "g1/g2/v7")) ==
              shapeid_local_array

        adios_define_attribute(file, "v4/a4", float(π))
        adios_define_attribute(file, "v5", "a5", [float(π)])
        adios_define_attribute(file, "g1/v6", "a6", [float(π), 0])

        adios_perform_puts!(file)
        close(file)
    end
    # run(`/Users/eschnett/src/CarpetX/Cactus/view/bin/bpls -aD $filename2`)

    @testset "High-level read tests " begin
        if adios2_version < v"2.9.0"
            # We need to use `mode_read` for ADIOS2 <2.9, and `mode_readRandomAccess` for ADIOS2 ≥2.9
            file = adios_open_serial(filename2, mode_read)
        else
            file = adios_open_serial(filename2, mode_readRandomAccess)
        end

        @test Set(adios_subgroup_names(file, "")) == Set(["g1"])
        @test_broken Set(adios_subgroup_names(file, "g1")) == Set(["g2"])
        @test Set(adios_subgroup_names(file, "g1")) == Set(["/g2"]) # don't want this

        @test Set(adios_all_attribute_names(file)) ==
              Set(["a1", "a2", "a3", "v4/a4", "v5/a5", "g1/v6/a6"])
        @test Set(adios_group_attribute_names(file, "g1")) == Set()
        @test Set(adios_group_attribute_names(file, "g1/v6")) ==
              Set(["g1/v6/a6"])

        @test adios_attribute_data(file, "a1") == float(π)
        if adios2_version < v"2.9.0"
            @test adios_attribute_data(file, "a2") == float(π)
        else
            @test adios_attribute_data(file, "a2") == [float(π)]
        end
        @test adios_attribute_data(file, "a3") == [float(π), 0]
        @test adios_attribute_data(file, "v4", "a4") == float(π)
        if adios2_version < v"2.9.0"
            @test adios_attribute_data(file, "v5/a5") == float(π)
        else
            @test adios_attribute_data(file, "v5/a5") == [float(π)]
        end
        @test adios_attribute_data(file, "g1/v6", "a6") == [float(π), 0]

        @test Set(adios_all_variable_names(file)) ==
              Set(["v1", "v3", "v4", "v5", "g1/v6", "g1/g2/v7"])
        @test Set(adios_group_variable_names(file, "g1")) == Set(["g1/v6"])
        @test Set(adios_group_variable_names(file, "g1/g2")) ==
              Set(["g1/g2/v7"])

        # Local values are converted to global arrays
        @test shapeid(inquire_variable(file.io, "v1")) == shapeid_global_array
        @test shapeid(inquire_variable(file.io, "v3")) == shapeid_local_array
        @test shapeid(inquire_variable(file.io, "v4")) == shapeid_local_array
        @test shapeid(inquire_variable(file.io, "v5")) == shapeid_local_array
        @test shapeid(inquire_variable(file.io, "g1/v6")) == shapeid_local_array
        @test shapeid(inquire_variable(file.io, "g1/g2/v7")) ==
              shapeid_local_array

        @test ndims(inquire_variable(file.io, "v1")) == 1
        @test ndims(inquire_variable(file.io, "v3")) == 1
        @test ndims(inquire_variable(file.io, "v4")) == 2
        @test ndims(inquire_variable(file.io, "v5")) == 3
        @test ndims(inquire_variable(file.io, "g1/v6")) == 4
        @test ndims(inquire_variable(file.io, "g1/g2/v7")) == 5

        @test shape(inquire_variable(file.io, "v1")) == (1,)
        @test shape(inquire_variable(file.io, "v3")) ≡ nothing
        @test shape(inquire_variable(file.io, "v4")) ≡ nothing
        @test shape(inquire_variable(file.io, "v5")) ≡ nothing
        @test shape(inquire_variable(file.io, "g1/v6")) ≡ nothing
        @test shape(inquire_variable(file.io, "g1/g2/v7")) ≡ nothing

        @test start(inquire_variable(file.io, "v1")) == (0,)
        @test start(inquire_variable(file.io, "v3")) ≡ nothing
        @test start(inquire_variable(file.io, "v4")) ≡ nothing
        @test start(inquire_variable(file.io, "v5")) ≡ nothing
        @test start(inquire_variable(file.io, "g1/v6")) ≡ nothing
        @test start(inquire_variable(file.io, "g1/g2/v7")) ≡ nothing

        @test count(inquire_variable(file.io, "v1")) == (1,)
        @test count(inquire_variable(file.io, "v3")) == (1,)
        @test count(inquire_variable(file.io, "v4")) == (1, 1)
        @test count(inquire_variable(file.io, "v5")) == (1, 1, 1)
        @test count(inquire_variable(file.io, "g1/v6")) == (1, 1, 1, 1)
        @test count(inquire_variable(file.io, "g1/g2/v7")) == (1, 1, 1, 1, 1)

        v1 = adios_get(file, "v1")
        @test !isready(v1)
        @test fetch(v1) == fill(float(ℯ), 1)
        @test isready(v1)
        v3 = adios_get(file, "v3")
        v4 = adios_get(file, "v4")
        @test !isready(v3)
        @test fetch(v3) == makearray(1, float(ℯ))
        @test fetch(v4) == makearray(2, float(ℯ))
        @test isready(v3)
        v5 = adios_get(file, "v5")
        v6 = adios_get(file, "g1/v6")
        v7 = adios_get(file, "g1/g2/v7")
        @test !isready(v5)
        adios_perform_gets(file)
        @test isready(v5)
        @test fetch(v5) == makearray(3, float(ℯ))
        @test fetch(v6) == makearray(4, float(ℯ))
        @test fetch(v7) == makearray(5, float(ℯ))
        close(file)
    end
end
