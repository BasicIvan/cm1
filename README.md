# CM1 v21.1 - Ivan Basic

This repository contains modified CM1 source in [`src/`](src/) and run scripts and inputs in [`RUN_CM1/`](RUN_CM1/). Start with the [run guide](RUN_CM1/README.md) before using the example configuration; its paths and domain settings are project specific.

The [local extensions guide](src/docs/README.md) and [annotated namelist reference](src/docs/README.namelist-ivan) are in `src/docs/`. The Levante build helper is [`scripts/compile.cm1.levante`](scripts/compile.cm1.levante); review its settings, then source it from the repository root. For binary output, use the [NetCDF conversion template](scripts/to_netcdf_scripts/README.md).

The source adds online time averages (`src/tmea.F`, developed by Jan Weinkaemmerer and adapted by Ivan Basic), passive tracer surface fluxes from `myflux.nc`, terrain from `myzs.nc`, and land use from `mylanduse.nc`, along with LES fixes. Search the source for `Ivan Basic` to locate many of these changes.

For the supplied terrain and land-use inputs, set `terrain_flag = .true.`, `itern = 12`, and `initsfc = 5` in `namelist.input`. Passive tracers use `iptra = 1` and `npt`; online averages use `dotmea = .true.`, `tmeafrq`, and `tmeaperiod`. The [run guide](RUN_CM1/README.md#namelist-settings-to-check) explains the dependencies and the `iconly = 1` setup check. Build with NetCDF support when reading the custom NetCDF inputs; see [`src/Makefile`](src/Makefile).

The [input preparation guide](RUN_CM1/INPUT/prepare/README.md) covers generating terrain, land use, a vertical grid, a sounding, and tracer fluxes for a new domain.

For questions about these modifications: basic@iau.uni-frankfurt.de.
