# Prepare input files for a CM1 run

These recipes cover terrain, land use, a vertical grid, an atmospheric sounding, and surface fluxes. The NetCDF examples come from the author's own projects and datasets. Their source files and configuration values illustrate the workflows; choose values that fit your simulation.

This folder can be moved as a unit. Its preparation scripts, processing code, and optional example sounding profile are all inside the five subfolders. It requires Python 3.10 or newer and the third-party packages in [`requirements.txt`](requirements.txt). From this folder, install them into your Python environment with `python3 -m pip install -r requirements.txt`.

Each recipe gives a command to run from the directory containing its script. Set `CM1_INPUT_DIR` to the directory where your CM1 run reads input files. For a run with an `INPUT` directory, set it from the run directory before following a recipe:

```sh
export CM1_INPUT_DIR="$(pwd)/INPUT"
mkdir -p "$CM1_INPUT_DIR"
```

In this checkout, the run directory is `RUN_CM1/`, so the command above points to `RUN_CM1/INPUT/` when run there. `cm1run` copies files from that directory into each job directory. Keep `CM1_INPUT_DIR` set when changing into a recipe subdirectory; run the recipes from their own directories. Numbered case folders under `INPUT/`, when available, contain examples that can be selected instead of generating new inputs; several are gitignored and may be absent from a fresh clone.

| Output file | Recipe | Input you supply |
| --- | --- | --- |
| `myzs.nc` | [Terrain](myzs/README.md) | Elevation raster and horizontal domain |
| `mylanduse.nc` | [Land use](mylanduse/README.md) | Classified land-use NetCDF and horizontal domain |
| `input_grid_z` | [Vertical grid](input_grid_z/README.md) | Layer heights and spacings |
| `input_sounding` | [Sounding](input_sounding/README.md) | Surface state and vertical profiles |
| `myflux.nc` | [Surface fluxes](myflux/README.md) | Emission fields, time profiles, and simulation period |

Before running CM1, compare each generated file with the run's `namelist.input`:

- Terrain, land use, and fluxes must cover the intended horizontal domain and match `nx` and `ny`. The flux workflow resizes arrays without georeferencing them, so check its source coverage and orientation separately.
- With `stretch_z = 4`, set `nz` to the value printed by the vertical-grid script. Extend the sounding through the grid top.
- Check that the flux time range and four components match the run's passive-tracer setup and `npt`. The model requires the file's `npt` to be at least the namelist `npt`; it uses only the requested components. See the [run guide](../../README.md#namelist-settings-to-check) for the current interaction between `dotmea`, `iptra`, and `npt`.
- Put the outputs under the filenames expected by CM1. Inspect NetCDF headers with `ncdump -h`.

The three NetCDF files use different variable layouts. The terrain and flux writers keep their established `NETCDF4_CLASSIC` and float64 settings; land use retains the structure and metadata of its classified source dataset. Use each workflow for its corresponding file.
