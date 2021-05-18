# Generate documentation with this command:
# (cd docs && julia --color=yes make.jl)

push!(LOAD_PATH, "..")

using Documenter
using ADIOS2

makedocs(; sitename="ADIOS2", format=Documenter.HTML(), modules=[ADIOS2])

deploydocs(; repo="github.com/eschnett/ADIOS2.jl.git", devbranch="main",
           push_preview=true)
