# Running CM1

`cm1run` submits a series of Slurm jobs with restarts. Each job advances the model by `simulation_seconds_per_job` in `job.input`; `num_jobs` sets the total number of jobs, including the initial run. `walltime_per_job` is the separate Slurm wall-clock limit. For example, `simulation_seconds_per_job=7200.0` and `num_jobs=4` request eight simulated hours across four jobs (unless the namelist requests initialization only). `cm1run_bigjobs` is an alternative with different MPI settings. Both scripts are configured for the author's cluster and need local path, account, and Slurm settings before use.

## Job configuration

Edit [`job.input`](job.input) before submitting:

| Variable | Meaning |
| --- | --- |
| `model_executable` | Path to the compiled CM1 executable. |
| `output_root` | Parent directory for cases; each run uses `output_root/case_name`. |
| `case_name` | Output subdirectory and Slurm job name. |
| `nodes` | Slurm node count per job. |
| `mpi_ranks_per_node` | MPI ranks per node (`--ntasks-per-node`). |
| `cpus_per_task` | CPU cores allocated per MPI rank (`--cpus-per-task`); the supplied setup uses pure MPI with a value of 1. |
| `stack_size_kib` | Per-process stack limit in KiB (`ulimit -s`). |
| `walltime_per_job` | Slurm wall-clock limit per job, in `HH:MM:SS`. |
| `simulation_seconds_per_job` | Simulated seconds per job; sets CM1's `run_time` and `rstfrq`. |
| `num_jobs` | Total jobs, including the initial run; restart jobs number `num_jobs - 1`. |

Existing personal copies of `job.input` must use these names. CM1 namelist names
such as `run_time` and `rstfrq` are unchanged.

## Set up a case

1. Build the modified source in [`../src/`](../src/) with NetCDF support for the custom `.nc` inputs. The [local extensions guide](../src/docs/README.md) links to the Levante build helper in `../scripts/`. Set `model_executable` in [`job.input`](job.input) to that executable. Set `output_root`, resources, `case_name`, `walltime_per_job`, `simulation_seconds_per_job`, and `num_jobs` for your cluster.
2. Select a namelist from [`INPUT/1namelist/`](INPUT/1namelist/) or edit [`INPUT/namelist.input`](INPUT/namelist.input). The latter is the active file copied into each run. Copy a suitable sounding and vertical grid to `INPUT/input_sounding` and `INPUT/input_grid_z`. Put terrain, flux, and land-use files at `INPUT/myzs.nc`, `INPUT/myflux.nc`, and `INPUT/mylanduse.nc` when your namelist uses them; select `INPUT/LANDUSE.TBL` as needed. The numbered `INPUT/` folders in this working copy contain case examples, but several are gitignored and may be absent from a fresh clone. For a new domain, see [`INPUT/prepare/`](INPUT/prepare/README.md).
3. Check the namelist and input dimensions, coordinates, and time coverage. Set `INPUTDIR` near the top of `cm1run` (or `cm1run_bigjobs`) to this checkout's `RUN_CM1/INPUT`. Setup and the generated `cm1.exe.run` script both use `output_root/case_name` as the run directory.
4. From `RUN_CM1/`, run `./cm1run` to prepare and submit the jobs. It copies the active inputs to `output_root/case_name`, links `model_executable`, and uses `INPUT/prep_namelist.py` to create `namelist.input00`, `01`, etc. That helper sets CM1's `run_time` and `rstfrq` to `simulation_seconds_per_job`, then sets `irst` and `rstnum` for each job. The generated script submits the next job after each run.

Choose a new output directory or case name for a new case. If `output_root/case_name` exists with a `COUNTER` file, `cm1run` stops; if it exists without one, the script removes that directory before setup.

For `output_format = 1` (binary output), use the [NetCDF conversion template](../scripts/to_netcdf_scripts/README.md) after the run. Binary output is generally faster for large runs but needs this extra step if NetCDF files are required.

## Namelist settings to check

- `iconly = 1` requests initial conditions only: CM1 writes initialization output and stops before a simulation. Use it for a short setup check, inspect the log and output, then set `iconly = 0` for a full run. The `case_name` does not set this switch. Example check namelists are under `INPUT/1namelist/SwissMidlands_2026/iconly/`.
- `terrain_flag = .true.` with `itern = 12` reads `myzs.nc`; `initsfc = 5` reads `mylanduse.nc`. Both require NetCDF support and files whose horizontal dimensions match `nx` and `ny`. `stretch_z = 4` reads `input_grid_z`; set `nz` to match it and extend `input_sounding` above the grid top.
- `iptra = 1` enables passive tracers. If `myflux.nc` is present, its `nx` and `ny` must match the run, it needs at least two time levels, and its `npt` must be at least the namelist's `npt` (extra file tracers are ignored). Without that file, the source uses constant tracer fluxes. The bundled flux preparer writes four components in the order GPP, respiration, anthropogenic CO2, anthropogenic CH4. Check that its hourly time span covers the simulation.
- `dotmea = .true.` enables online time averages. `tmeafrq` is the sampling interval in seconds; `tmeaperiod` is the window before each output (`tapfrq`) in seconds. `tmeaperiod = 0` keeps averaging between outputs. For a positive window, use `0 < tmeaperiod <= tapfrq` and `tmeafrq <= tmeaperiod`; for example, `tapfrq = 3600`, `tmeafrq = 30`, `tmeaperiod = 600` averages the last ten minutes before each hourly output.
- With `dotmea = .true.` and `iptra = 1`, `src/tmea.F` always sets up and samples all six tracer fields, regardless of `npt`. In `src/solve1.F`, surface fluxes are initialized for the configured tracers, including default fluxes for tracers 5 and 6 when `npt` includes them (these are overridden if `myflux.nc` is loaded). This does not create missing tracer fields. To use fewer than six tracers with time averaging, modify `tmea.F` to register and sample only the intended fields, and modify `solve1.F` if their flux setup must change; changing `npt` alone is insufficient. The active namelist has `npt = 3`, so review it before running. The four-component `myflux.nc` written by the bundled preparer cannot be used with `npt = 6`: the file must contain at least the namelist's `npt` components.

These are case choices, not universal values. Review the other active namelist settings, especially domain size, time step, output flags, and restart frequency, before submitting a large run.
