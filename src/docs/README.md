# CM1 local extensions

The source in [`../`](../) is based on CM1 release 21.1 and contains local extensions for
passive-tracer fluxes, online time averaging, land-use input, and related model
integration.

[README.namelist-ivan](README.namelist-ivan) includes Ivan Basic’s notes on option combinations
restricted by the code but not covered in the original documentation. 
It also documents the additional parameters introduced in this source tree.

For the Levante build helper, see [`../../scripts/compile.cm1.levante`](../../scripts/compile.cm1.levante).
Review its module versions and the compiler/NetCDF settings in
[`../Makefile`](../Makefile), then run
`source scripts/compile.cm1.levante` from the repository root. The helper
defaults to this checkout; set `cm1_folder` before sourcing to build another
checkout. For run setup, see the [run guide](../../RUN_CM1/README.md).

## Authorship

- `tmea.F` was originally written by Jan Weinkaemmerer in 2019/20. Ivan Basic
  integrated it into this CM1 source tree and subsequently adapted and extended
  it. `tmea_full.F` retains the fuller variant for reference; the Makefile builds
  `tmea.F`.
- `myflux.F` was written by Ivan Basic.
- Changes marked `Ivan Basic` elsewhere connect these modules to CM1 or support
  the local modelling setup.

## Local changes

### Online time averaging (`tmea`)

`tmea.F` provides setup and calculation routines for online time-averaged
fields. The integration adds `dotmea`, `tmeafrq`, and `tmeaperiod` to namelist
`param14`, schedules accumulation in `cm1.F`, prepares the required diagnostic
budgets, and writes the resulting two- and three-dimensional fields through
`writeout.F`.

Add `tmeaperiod` to the existing `&param14` section of `namelist.input` to
average only over a window immediately before each model output. All intervals
are in seconds. For example, keep `tapfrq = 3600.0` in `&param1` and use:

```fortran
&param14
  ! Keep any existing domain-diagnostic settings here.
  dotmea     = .true.,
  tmeafrq    = 10.0,
  tmeaperiod = 600.0,
/
```

This samples every 10 seconds during the final 10 minutes before each hourly
output. The existing sampling clock continues at its normal cadence. A simple
check of `time_left = taptim - mtime` gates the averaging calls and sample-count
increment in `cm1.F`. Here `taptim` is the next scheduled output time. Samples
at the beginning and end of the window are included when the clock reaches
them; no fixed number of samples is required. The running mean uses the actual
sample count, and a difference of one sample between windows is acceptable.
`tmeafrq <= 0` samples every model step inside the window.

`tmeaperiod = 0.0` (the default when omitted) preserves averaging between
outputs. A positive period requires `0 < tmeaperiod <= tapfrq`, and a positive
sample interval must not exceed the period. With `dotmea = .true.`, setting
`tmeaperiod > tapfrq` stops CM1 during parameter validation in `param.F`, before
model integration, with the message `TMEA requires 0 < tmeaperiod <= tapfrq.`
The output at initialization still contains the initial instantaneous values.

For this simple implementation, restart times must coincide with model output
times: use `rstfrq = N * tapfrq`, where N is a positive integer, and keep that
alignment when resuming. For hourly output, use `rstfrq = 3600`, `7200`, etc.
CM1 writes the completed average and clears its accumulator before writing the
restart at the same time, so there is no unfinished average to preserve. TMEA
fields and counters are not stored in restart files, and their format is
unchanged. Restarting inside an averaging window loses the samples collected
before that restart. No change to `restart_reset_frqtim` is needed for restarts
at output times with the same `tapfrq`.

The local extensions include passive-tracer means and moments, resolved fluxes,
subgrid TKE diagnostics, restart handling, and supporting diagnostic indices.

### Spatially and temporally varying tracer fluxes (`myflux`)

`myflux.F` optionally reads passive-tracer surface fluxes from `myflux.nc` and
broadcasts them to all MPI processes. `solve1.F` interpolates the supplied
hourly fluxes in time and applies them through the passive-tracer turbulence
call.

The NetCDF file is expected to contain dimensions named `nt`, `nx`, `ny`, and
`npt`, and a variable named `flux`. Its `nx` and `ny` must match the CM1
domain, and it must contain at least two time levels.

`myflux.nc` is optional. If it is absent, or CM1 was built without NetCDF
support, constant surface fluxes are used: `1.0e-9` for every tracer, overridden
by `1.1e-7` for tracer 5 and `0.0` for tracer 6 when those tracers exist.

The model and file tracer counts are handled as follows:

- If model `npt` is greater than file `npt`, CM1 stops with an error.
- If model `npt` is equal to file `npt`, all file tracers are used.
- If model `npt` is less than file `npt`, only the first model `npt` tracers
  from the file are used.

### Required custom NetCDF inputs

The following files are mandatory only when their corresponding custom option
is selected:

- `terrain_flag = .true.` and `itern = 12` require `myzs.nc`, with dimensions
  `nx` and `ny` and a variable named `myzs`.
- `initsfc = 5` requires `mylanduse.nc`, with dimensions `x` and `y` and a
  variable named `landuse`.

For both options, CM1 stops with a clear error if the file is absent, NetCDF
support is unavailable, a required dimension or variable is missing, the
horizontal dimensions differ from the model domain, or the data cannot be
read.

### Other supporting changes

- `init_terrain.F` and `init_surface.F` provide the required `myzs.nc` and
  `mylanduse.nc` input paths described above.
- `param.F`, `input.F`, `misclibs.F`, `solve1.F`, `solve2.F`, `cm1.F`, and
  `writeout.F` contain the TMEA and tracer-flux integration.
- `turb.F` preserves MYNN boundary-layer height as an above-ground-level
  quantity over terrain.
- The RRTMG longwave and shortwave modules contain a local seed-generation
  adjustment.
- The Makefile builds `tmea.F` and `myflux.F` and declares their dependencies.

