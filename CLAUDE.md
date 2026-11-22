# CLAUDE.md

ADIOS2.jl is a Julia wrapper around the C API of
[ADIOS2](https://github.com/ornladios/ADIOS2) (Adaptable Input Output
System). It supports serial and MPI-parallel I/O.

## Commands

```sh
# Build (generates deps/deps.jl; required before first use)
julia --project=. -e 'using Pkg; Pkg.build()'

# Run the test suite (serial)
julia --project=. -e 'using Pkg; Pkg.test()'

# Run the test suite under MPI with 2 ranks (as CI does)
julia --project=. -e 'using MPI; MPI.install_mpiexecjl()'
~/.julia/bin/mpiexecjl -n 2 --project=. julia -e 'using Pkg; Pkg.test()'

# Build the docs
(cd docs && julia make.jl)
```

Format code with JuliaFormatter (settings in `.JuliaFormatter.toml`:
YAS style, 4-space indent, 80-column margin).

## Layout

- `src/ADIOS2.jl` — module entry; loads `deps/deps.jl`, defines
  helpers (`Maybe`, `free`), includes the other files.
- `src/types.jl` — enums mirroring the C API (`Error`, `AType`,
  `Mode`, `StepMode`, …) and Julia ↔ ADIOS type mapping
  (`adios_type`, `julia_type`).
- `src/adios.jl`, `io.jl`, `variable.jl`, `attribute.jl`, `engine.jl`
  — thin low-level wrappers, one per ADIOS2 C object, built from
  direct `ccall`s into `libadios2_c` / `libadios2_c_mpi`.
- `src/highlevel.jl` — convenience layer (`AdiosFile`,
  `adios_open_serial`, `adios_define_attribute`, `adios_put!`, …).
- `src/extended_highlevel/adios_load.jl` — `adios_load` for reading
  whole variables / step ranges / slices.
- `deps/build.jl` — writes `deps/deps.jl` (git-ignored). Uses
  `ADIOS2_jll` by default, or a system library if `JULIA_ADIOS2_PATH`
  is set.
- `test/runtests.jl` — initializes MPI, then includes the per-topic
  test files. Tests run both with 1 rank and with multiple ranks;
  `use_mpi` gates the MPI-specific parts.

## Conventions

- **Index order**: ADIOS2 is row-major/C order; Julia is
  column-major. Shapes, starts and counts are `reverse`d at the C
  boundary, and user-facing `start` values in the high-level API are
  1-based. Keep this consistent when adding functions.
- Each wrapper struct holds a `ptr::Ptr{Cvoid}`. `Adios` is a
  `mutable struct` with a finalizer; the others are owned by it.
- Constructors/lookups that can fail return `nothing` (the C API
  returns `NULL`) rather than throwing.
- Every exported function is preceded by its own `export` line and a
  docstring, matching the existing files.
- String reads use `adios2_get_string` when the library provides it
  (`have_adios2_get_string`), with a fallback otherwise.
- Supported Julia: 1.10+. `ADIOS2_jll` compat is pinned in
  `Project.toml`; bump the patch version in `Project.toml` for
  releases.
