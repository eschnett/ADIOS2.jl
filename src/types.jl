# Types

export Error
export error_none, error_invalid_argument, error_system_error,
       error_runtime_error, error_exception
"""
    @enum Error begin
        error_none
        error_invalid_argument
        error_system_error
        error_runtime_error
        error_exception
    end

`Error` return types for all ADIOS2 functions

Based on the [library C++ standardized
exceptions](https://en.cppreference.com/w/cpp/error/exception). Each
error will issue a more detailed description in the standard error
output, stderr
"""
@enum Error begin
    error_none = 0
    error_invalid_argument = 1
    error_system_error = 2
    error_runtime_error = 3
    error_exception = 4
end

@enum AType begin
    type_unknown = -1
    type_string = 0
    type_float = 1
    type_double = 2
    type_float_complex = 3
    type_double_complex = 4
    type_int8_t = 5
    type_int16_t = 6
    type_int32_t = 7
    type_int64_t = 8
    type_uint8_t = 9
    type_uint16_t = 10
    type_uint32_t = 11
    type_uint64_t = 12
    type_long_double = 13
end

# We omit `type_long_double` that we cannot handle
const adios_types = AType[type_string, type_float, type_double,
                          type_float_complex, type_double_complex, type_int8_t,
                          type_int16_t, type_int32_t, type_int64_t,
                          type_uint8_t, type_uint16_t, type_uint32_t,
                          type_uint64_t]
adios_type(::Type{String}) = type_string
adios_type(::Type{Float32}) = type_float
adios_type(::Type{Float64}) = type_double
adios_type(::Type{Complex{Float32}}) = type_float_complex
adios_type(::Type{Complex{Float64}}) = type_double_complex
adios_type(::Type{Int8}) = type_int8_t
adios_type(::Type{Int16}) = type_int16_t
adios_type(::Type{Int32}) = type_int32_t
adios_type(::Type{Int64}) = type_int64_t
adios_type(::Type{UInt8}) = type_uint8_t
adios_type(::Type{UInt16}) = type_uint16_t
adios_type(::Type{UInt32}) = type_uint32_t
adios_type(::Type{UInt64}) = type_uint64_t

const julia_types = Type[String, Float32, Float64, Complex{Float32},
                         Complex{Float64}, Int8, Int16, Int32, Int64, UInt8,
                         UInt16, UInt32, UInt64]
julia_type(type::AType) = julia_types[Int(type) + 1]

export Mode
export mode_undefined, mode_write, mode_read, mode_append, mode_deferred,
       mode_sync
"""
    @enum Mode begin
        mode_undefined
        mode_write
        mode_read
        mode_append
        mode_deferred
        mode_sync
    end

Mode specifies for various functions. `write`, `read`, `append` are
used for file operations, `deferred`, `sync` are used for get and put
operations.
"""
@enum Mode begin
    mode_undefined = 0
    mode_write = 1
    mode_read = 2
    mode_append = 3
    mode_deferred = 4
    mode_sync = 5
end

export ShapeId
export shapeid_unknown, shapeid_global_value, shapeid_global_array,
       shapeid_joined_array, shapeid_local_value, shapeid_local_array
"""
    @enum ShapeId begin
        shapeid_unknown
        shapeid_global_value
        shapeid_global_array
        shapeid_joined_array
        shapeid_local_value
        shapeid_local_array
    end
"""
@enum ShapeId begin
    shapeid_unknown = -1
    shapeid_global_value = 0
    shapeid_global_array = 1
    shapeid_joined_array = 2
    shapeid_local_value = 3
    shapeid_local_array = 4
end
const shapeid_strings = String["unknown", "global_value", "global_array",
                               "joined_array", "local_value", "local_array"]
shapeid_string(shapeid::ShapeId) = shapeid_strings[Int(shapeid) + 2]
Base.show(io::IO, shapeid::ShapeId) = print(io, shapeid_string(shapeid))
