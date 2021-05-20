# Attributes

export Attribute
"""
    struct Attribute

Holds a C pointer `adios2_attribute *`.
"""
struct Attribute
    ptr::Ptr{Cvoid}
end
