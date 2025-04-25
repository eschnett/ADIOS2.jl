# Test basic API

const rankstr = @sprintf "%06d" comm_rank

if comm_rank == comm_root
    const dirname = Filesystem.mktempdir()
end
if use_mpi
    if comm_rank == comm_root
        MPI.bcast(dirname, comm_root, comm)
    else
        const dirname = MPI.bcast(nothing, comm_root, comm)
    end
end
const filename = "$dirname/test.bp"

# "BP3", "BP4", "BP5", "HDF5", "SST", "SSC", "DataMan", "Inline", "Null"
const ENGINE_TYPE = "BP4"

@testset "File write tests" begin
    # Set up ADIOS
    if use_mpi
        adios = adios_init_mpi(comm)
    else
        adios = adios_init_serial()
    end
    @test adios isa Adios
    @test match(r"Adios\(.+\)", string(adios)) ≢ nothing
    @test match(r"Adios\(0x[0-9a-f]+\)", showmime(adios)) ≢ nothing

    io = declare_io(adios, "IO")
    @test io isa AIO
    @test match(r"AIO\(.+\)", string(io)) ≢ nothing
    @test match(r"AIO\(0x[0-9a-f]+\)", showmime(io)) ≢ nothing

    # Define some variables
    variables = Dict()
    for T in
        Type[String, Float32, Float64, Complex{Float32}, Complex{Float64}, Int8,
             Int16, Int32, Int64, UInt8, UInt16, UInt32, UInt64]
        val = T ≡ String ? "42" : T(42)
        val::T

        # Global value
        nm = "gvalue.p$rankstr.$T"
        gval = define_variable(io, nm, T)
        @test gval isa Variable
        @test match(r"Variable\(name=.+,type=.+,shapeid=.+,shape=.+\)",
                    string(gval)) ≢ nothing
        @test match(r"Variable\(.+\)", showmime(gval)) ≢ nothing
        variables[(shapeid_global_value, -1, -1, T)] = (nm, gval)

        # Local value
        nm = "lvalue.p$rankstr.$T"
        lval = define_variable(io, nm, val)
        @test lval isa Variable
        @test match(r"Variable\(name=.+,type=.+,shapeid=.+,shape=.+\)",
                    string(lval)) ≢ nothing
        @test match(r"Variable\(.+\)", showmime(lval)) ≢ nothing
        variables[(shapeid_local_value, -1, -1, T)] = (nm, lval)

        # String arrays are not supported
        if T ≢ String
            for D in 1:3, len in 0:2
                # size
                sz = ntuple(d -> len == 0 ? 0 : len == 1 ? 1 : d, D)
                arr = fill(val, sz)

                # shape, start, count of global array
                cs = ntuple(d -> d < D ? 1 : comm_size, D)
                cr = ntuple(d -> d < D ? 0 : comm_rank, D)
                sh = cs .* sz
                st = cr .* sz
                co = sz

                # Global array
                nm = "garray.$T.$D.$len"
                garr = define_variable(io, nm, T, sh, st, co)
                @test garr isa Variable
                @test match(r"Variable\(name=.+,type=.+,shapeid=.+,shape=.+\)",
                            string(garr)) ≢ nothing
                @test match(r"Variable\(.+\)", showmime(garr)) ≢ nothing
                variables[(shapeid_global_array, D, len, T)] = (nm, garr)

                # Local array
                nm = "larray.p$rankstr.$T.$D.$len"
                larr = define_variable(io, nm, arr)
                @test larr isa Variable
                @test match(r"Variable\(name=.+,type=.+,shapeid=.+,shape=.+\)",
                            string(larr)) ≢ nothing
                @test match(r"Variable\(.+\)", showmime(larr)) ≢ nothing
                variables[(shapeid_local_array, D, len, T)] = (nm, larr)
            end
        end
    end

    # Check variables
    allvars = inquire_all_variables(io)
    @test Set(allvars) == Set([var for (name, var) in values(variables)])

    var0 = inquire_variable(io, "not a variable")
    @test var0 isa Nothing

    for ((si, D, len, T), (nm, var)) in variables
        var1 = inquire_variable(io, nm)
        @test var1 isa Variable
        @test nm == name(var1)
        @test type(var1) == T
        @test shapeid(var1) == si
        if si == shapeid_global_value
            @test ndims(var1) == 0
            @test shape(var1) == ()
            @test start(var1) == ()
            @test count(var1) == ()
        elseif si == shapeid_local_value
            @test ndims(var1) == 0
            @test shape(var1) ≡ nothing
            @test start(var1) ≡ nothing
            @test count(var1) ≡ ()
        elseif si == shapeid_global_array
            sz = ntuple(d -> len == 0 ? 0 : len == 1 ? 1 : d, D)
            cs = ntuple(d -> d < D ? 1 : comm_size, D)
            cr = ntuple(d -> d < D ? 0 : comm_rank, D)
            sh = cs .* sz
            st = cr .* sz
            co = sz
            @test ndims(var1) == D
            @test shape(var1) == sh
            @test start(var1) == st
            @test count(var1) == co
        elseif si == shapeid_local_array
            sz = ntuple(d -> len == 0 ? 0 : len == 1 ? 1 : d, D)
            @test ndims(var1) == D
            @test shape(var1) ≡ nothing
            @test start(var1) ≡ nothing
            @test count(var1) == sz
        else
            error("internal error")
        end
    end

    # Define some attributes
    attributes = Dict()
    for T in Type[String, Float32, Float64,
         # Currently broken, see
         # <https://github.com/ornladios/ADIOS2/issues/2734>
         # Complex{Float32}, Complex{Float64},
                  Int8, Int16, Int32, Int64, UInt8, UInt16, UInt32, UInt64]
        val = T ≡ String ? "42" : T(42)
        val::T

        # Attribute
        nm = "value.p$rankstr.$T"
        attr = define_attribute(io, nm, val)
        @test attr isa Attribute
        @test match(r"Attribute\(name=.+,type=.+,is_value=(false|true),size=.+,data=.+\)",
                    string(attr)) ≢ nothing
        @test match(r"Attribute\(.+\)", showmime(attr)) ≢ nothing
        attributes[(-1, -1, "", T)] = (nm, attr)

        # Variable attribute
        nm = "value.p$rankstr.$T"
        varname = variables[(shapeid_global_value, -1, -1, T)][1]
        attr = define_variable_attribute(io, nm, val, varname)
        @test attr isa Attribute
        @test match(r"Attribute\(name=.+,type=.+,is_value=(false|true),size=.+,data=.+\)",
                    string(attr)) ≢ nothing
        @test match(r"Attribute\(.+\)", showmime(attr)) ≢ nothing
        attributes[(-1, -1, varname, T)] = ("$varname/$nm", attr)

        # Attribute arrays need to have at least one element (why?)
        for len in 1:2:3
            vals = (T ≡ String ? String["42", "", "44"] : T[42, 0, 44])[1:len]

            # Attribute array
            nm = "array.p$rankstr.$T.$len"
            arr = define_attribute_array(io, nm, vals)
            @test arr isa Attribute
            @test match(r"Attribute\(name=.+,type=.+,is_value=(false|true),size=.+,data=.+\)",
                        string(arr)) ≢ nothing
            @test match(r"Attribute\(.+\)", showmime(arr)) ≢ nothing
            attributes[(1, len, "", T)] = (nm, arr)

            # Variable attribute array
            nm = "array.p$rankstr.$T.$len"
            varname = variables[(shapeid_global_value, -1, -1, T)][1]
            arr = define_variable_attribute_array(io, nm, vals, varname)
            @test match(r"Attribute\(name=.+,type=.+,is_value=(false|true),size=.+,data=.+\)",
                        string(arr)) ≢ nothing
            @test match(r"Attribute\(.+\)", showmime(arr)) ≢ nothing
            @test arr isa Attribute
            attributes[(1, len, varname, T)] = ("$varname/$nm", arr)
        end
    end

    # Check attributes
    allattrs = inquire_all_attributes(io)
    @test Set(allattrs) == Set([attr for (name, attr) in values(attributes)])

    attr0 = inquire_attribute(io, "not an attribute")
    @test attr0 isa Nothing
    attr0 = inquire_variable_attribute(io, "not an attribute", "not a variable")
    @test attr0 isa Nothing

    for ((D, len, varname, T), (nm, attr)) in attributes
        attr1 = inquire_attribute(io, nm)
        @test attr1 isa Attribute
        @test nm == name(attr1)
        @test type(attr1) == T
        if D == -1
            @test is_value(attr)
            @test size(attr) == 1
            val = T ≡ String ? "42" : T(42)
            @test data(attr) == val
        else
            @test !is_value(attr)
            @test size(attr) == len
            vals = (T ≡ String ? String["42", "", "44"] : T[42, 0, 44])[1:len]
            @test data(attr) == vals
        end
    end

    err = set_engine(io, ENGINE_TYPE)
    @test err ≡ error_none

    etype = engine_type(io)
    # @test etype == "File"
    @test etype == ENGINE_TYPE

    # Write the file
    engine = open(io, filename, mode_write)
    @test engine isa Engine

    # Schedule variables for writing
    for ((si, D, len, T), (nm, var)) in variables
        val = T ≡ String ? "42" : T(42)
        if si ∈ (shapeid_global_value, shapeid_local_value)
            err = put!(engine, var, val)
            @test err ≡ error_none
        elseif si ∈ (shapeid_global_array, shapeid_local_array)
            sz = ntuple(d -> len == 0 ? 0 : len == 1 ? 1 : d, D)
            # Construct a single number from a tuple
            ten(i, s) = i == () ? s : ten(i[2:end], 10s + i[1])
            # Convert to type `T`
            function mkT(T, s)
                return (T ≡ String ? "$s" :
                        T <: Union{AbstractFloat,Complex} ? T(s) : s % T)::T
            end
            arr = T[mkT(T, ten(Tuple(i), 0)) for i in CartesianIndices(sz)]
            arr1 = rand(Bool) ? arr : @view arr[:]
            err = put!(engine, var, arr1)
            @test err ≡ error_none
        else
            error("internal error")
        end
    end

    # Write the variables
    err = perform_puts!(engine)
    @test err ≡ error_none

    # Minima and maxima are only available when reading a file
    # for ((si, D, T), (nm, var)) in variables
    #     val = T ≡ String ? "42" : T(42)
    #      @test minimum(var) == val
    #      @test maximum(var) == val
    # end

    err = close(engine)
    @test err ≡ error_none

    finalize(adios)
end

# Call gc to test finalizing the Adios object
GC.gc(true)

@testset "File read tests" begin
    # Set up ADIOS
    if use_mpi
        adios = adios_init_mpi(comm)
    else
        adios = adios_init_serial()
    end
    @test adios isa Adios

    io = declare_io(adios, "IO")
    @test io isa AIO

    # Open the file
    if ADIOS2_VERSION < v"2.9.0"
        # We need to use `mode_read` for ADIOS2 <2.9, and `mode_readRandomAccess` for ADIOS2 ≥2.9
        engine = open(io, filename, mode_read)
    else
        engine = open(io, filename, mode_readRandomAccess)
    end
    @test engine isa Engine

    err = set_engine(io, ENGINE_TYPE)
    @test err ≡ error_none

    etype = engine_type(io)
    # @test etype == "File"
    @test etype == ENGINE_TYPE

    # Inquire about all variables
    variables = Dict()
    for T in
        Type[String, Float32, Float64, Complex{Float32}, Complex{Float64}, Int8,
             Int16, Int32, Int64, UInt8, UInt16, UInt32, UInt64]
        # Global value
        nm = "gvalue.p$rankstr.$T"
        gval = inquire_variable(io, nm)
        @test gval isa Variable
        variables[(shapeid_global_value, -1, -1, T)] = (nm, gval)

        # Local value
        nm = "lvalue.p$rankstr.$T"
        lval = inquire_variable(io, nm)
        @test lval isa Variable
        variables[(shapeid_local_value, -1, -1, T)] = (nm, lval)

        # String arrays are not supported
        if T ≢ String
            for D in 1:3, len in 0:2
                # Global array
                nm = "garray.$T.$D.$len"
                garr = inquire_variable(io, nm)
                @test garr isa Variable
                variables[(shapeid_global_array, D, len, T)] = (nm, garr)

                # Local array
                nm = "larray.p$rankstr.$T.$D.$len"
                larr = inquire_variable(io, nm)
                @test larr isa Variable
                variables[(shapeid_local_array, D, len, T)] = (nm, larr)
            end
        end
    end

    # Check variables
    allvars = inquire_all_variables(io)
    if comm_size == 1
        @test Set(allvars) == Set([var for (name, var) in values(variables)])
    else
        @test Set(allvars) ⊇ Set([var for (name, var) in values(variables)])
    end

    var0 = inquire_variable(io, "not a variable")
    @test var0 isa Nothing

    for ((si, D, len, T), (nm, var)) in variables
        var1 = inquire_variable(io, nm)
        @test var1 isa Variable
        @test nm == name(var1)
        @test type(var1) == T
        if si == shapeid_global_value
            # Global values are re-interpreted as global arrays
            @test shapeid(var1) == si
            @test ndims(var1) == 0
            @test shape(var1) == ()
            @test start(var1) == ()
            @test count(var1) == ()
        elseif si == shapeid_local_value
            # Local values are re-interpreted as global arrays
            @test shapeid(var1) == shapeid_global_array
            @test ndims(var1) == 1
            if ENGINE_TYPE == "BP4"
                @test shape(var1) == (1,)
            else
                @test shape(var1) == (comm_size,)
            end
            @test start(var1) == (0,)
            if ENGINE_TYPE == "BP4"
                @test count(var1) == (1,)
            else
                @test count(var1) == (comm_size,)
            end
        elseif si == shapeid_global_array
            sz = ntuple(d -> len == 0 ? 0 : len == 1 ? 1 : d, D)
            cs = ntuple(d -> d < D ? 1 : comm_size, D)
            cr = ntuple(d -> d < D ? 0 : comm_rank, D)
            sh = cs .* sz
            st = cr .* sz
            co = sz
            if ENGINE_TYPE == "BP4" && len == 0
                # Empty global arrays are mis-interpreted as global values
                @test shapeid(var1) == shapeid_global_value
                @test ndims(var1) == 0
                @test shape(var1) == ()
                @test start(var1) == ()
                @test count(var1) == ()
            else
                @test shapeid(var1) == si
                @test ndims(var1) == D
                @test shape(var1) == sh
                if comm_size == 1
                    # With multiple processes, there are multiple
                    # blocks, and they each have a different starting
                    # offset
                    @test start(var1) == st
                    @test count(var1) == co
                else
                    @test_broken false
                end
                #TODO "need to select block to access variable"
            end
        elseif si == shapeid_local_array
            sz = ntuple(d -> len == 0 ? 0 : len == 1 ? 1 : d, D)
            if ENGINE_TYPE == "BP4" && len == 0
                # Empty local arrays are mis-interpreted as global values
                @test shapeid(var1) == shapeid_global_value
                @test ndims(var1) == 0
                @test shape(var1) == ()
                @test start(var1) == ()
                @test count(var1) == ()
            else
                @test shapeid(var1) == si
                @test ndims(var1) == D
                @test shape(var1) ≡ nothing
                @test start(var1) ≡ nothing
                @test count(var1) == sz
            end
        else
            error("internal error")
        end
    end

    # Read attributes
    attributes = Dict()
    for T in
        Type[String, Float32, Float64, Complex{Float32}, Complex{Float64}, Int8,
             Int16, Int32, Int64, UInt8, UInt16, UInt32, UInt64]
        # Complex attributes cannot be read via the C API (see
        # <https://github.com/ornladios/ADIOS2/issues/2734>)
        T <: Complex && continue

        # Attribute
        nm = "value.p$rankstr.$T"
        attr = inquire_attribute(io, nm)
        @test attr isa Attribute
        attributes[(-1, -1, "", T)] = (nm, attr)

        # Variable attribute
        nm = "value.p$rankstr.$T"
        varname = variables[(shapeid_global_value, -1, -1, T)][1]
        attr = inquire_variable_attribute(io, nm, varname)
        @test attr isa Attribute
        attributes[(-1, -1, varname, T)] = (nm, attr)

        # Attribute arrays need to have at least one element (why?)
        for len in 1:2:3
            # Attribute array
            nm = "array.p$rankstr.$T.$len"
            arr = inquire_attribute(io, nm)
            @test arr isa Attribute
            attributes[(1, len, "", T)] = (nm, arr)

            # Variable attribute array
            nm = "array.p$rankstr.$T.$len"
            varname = variables[(shapeid_global_value, -1, -1, T)][1]
            arr = inquire_variable_attribute(io, nm, varname)
            @test arr isa Attribute
            attributes[(1, len, varname, T)] = (nm, arr)
        end
    end

    # Check attributes
    allattrs = inquire_all_attributes(io)
    if comm_size == 1
        @test Set(allattrs) ==
              Set([attr for (name, attr) in values(attributes)])
    else
        @test Set(allattrs) ⊇ Set([attr for (name, attr) in values(attributes)])
    end

    attr0 = inquire_attribute(io, "not an attribute")
    @test attr0 isa Nothing
    attr0 = inquire_variable_attribute(io, "not an attribute", "not a variable")
    @test attr0 isa Nothing

    for ((D, len, varname, T), (nm, attr)) in attributes
        val = T ≡ String ? "42" : T(42)
        val::T

        attr1 = inquire_attribute(io, nm)
        @test attr1 isa Attribute
        @test nm == name(attr1)
        @test type(attr1) == T
        if D == -1
            @test is_value(attr)
            @test size(attr) == 1
            @test data(attr) == val
        else
            if ENGINE_TYPE == "BP4" && T ≢ String && len == 1
                # Length-1 non-string attribute arrays are mis-interpreted as values
                @test is_value(attr)
                @test size(attr) == len
                vals = (T ≡ String ? String["42", "", "44"] : T[42, 0, 44])[1:len]
                @test [data(attr)] == vals
            else
                @test !is_value(attr)
                @test size(attr) == len
                vals = (T ≡ String ? String["42", "", "44"] : T[42, 0, 44])[1:len]
                @test data(attr) == vals
            end
        end
    end

    # Schedule variables for reading
    buffers = Dict()
    for ((si, D, len, T), (nm, var)) in variables
        if si ∈ (shapeid_global_value, shapeid_local_value)
            # Local values are re-interpreted as global arrays
            if ENGINE_TYPE == "BP4" || comm_size == 1
                ref = Ref{T}()
            else
                ref = Array{T}(undef, comm_size)
            end
            err = get(engine, var, ref)
            if nm == "lvalue.p$rankstr.String"
                @test_broken err ≡ error_none
            else
                @test err ≡ error_none
            end
            buffers[(si, D, len, T)] = ref
        elseif si ∈ (shapeid_global_array, shapeid_local_array)
            co = count(var)
            arr = Array{T}(undef, co)
            arr1 = rand(Bool) ? arr : @view arr[:]
            err = get(engine, var, arr1)
            @test err ≡ error_none
            buffers[(si, D, len, T)] = arr
        else
            error("internal error")
        end
    end

    # Read variables
    err = perform_gets(engine)
    @test err ≡ error_none

    # Check variables
    for ((si, D, len, T), (nm, var)) in variables
        # String variables cannot be read (compare
        # <https://github.com/ornladios/ADIOS2/issues/2735>)
        T ≡ String && continue
        if si ∈ (shapeid_global_value, shapeid_local_value)
            val = T ≡ String ? "42" : T(42)
            @test all(buffers[(si, D, len, T)] .== val)
        elseif si ∈ (shapeid_global_array, shapeid_local_array)
            sz = ntuple(d -> len == 0 ? 0 : len == 1 ? 1 : d, D)
            # Construct a single number from a tuple
            ten(i, s) = i == () ? s : ten(i[2:end], 10s + i[1])
            # Convert to type `T`
            function mkT(T, s)
                return (T ≡ String ? "$s" :
                        T <: Union{AbstractFloat,Complex} ? T(s) : s % T)::T
            end
            arr = T[mkT(T, ten(Tuple(i), 0)) for i in CartesianIndices(sz)]
            if ENGINE_TYPE == "BP4" && len == 0
                # Empty global arrays are mis-interpreted as global values
                # There is a spurious value `0`
                @test buffers[(si, D, len, T)] == fill(T(0))
            else
                if comm_size == 1
                    @test buffers[(si, D, len, T)] == arr
                else
                    @test_broken false
                end
            end
        else
            error("internal error")
        end
    end

    err = close(engine)
    @test err ≡ error_none

    err = adios_finalize(adios)
    @test err ≡ error_none
end

# Call gc to test finalizing the Adios object
GC.gc(true)
