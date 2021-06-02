# Test internals

@testset "Internal tests" begin
    for jtype in ADIOS2.julia_types
        @test ADIOS2.julia_type(ADIOS2.adios_type(jtype)) ≡ jtype
    end
    for atype in ADIOS2.adios_types
        @test ADIOS2.adios_type(ADIOS2.julia_type(atype)) ≡ atype
    end
end
