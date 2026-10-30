# Converting binary CM1 output to NetCDF

Use this template when CM1's namelist has `output_format = 1` (GrADS/direct-access
binary output). Binary output is generally faster for large runs, especially at
high MPI process counts, but requires an extra post-processing step to obtain
NetCDF files. With `output_format = 2`, CM1 writes NetCDF directly and this
conversion is unnecessary. See the [namelist reference](../../src/docs/README.namelist-ivan)
for output options.

[`convert_to_netcdf.sh`](convert_to_netcdf.sh) uses CDO's `import_binary` to read
the `.ctl` descriptor and associated `.dat` files, selects variables, assigns
coordinates and times, and writes NetCDF4. It replaces the separate variable-group
scripts; their selections are preserved as commented examples below the command.

1. Copy `convert_to_netcdf.sh`, `cm1_grid.txt`, and `cm1_zaxis.txt` into the
   directory containing your binary output (usually the run's `output/` folder
   after the job chain finishes). Keep the `.ctl` and every `.dat` file it
   references together. This assumes an assembled output stream readable by CDO;
   per-MPI-process output (`output_filetype = 3`) must first be combined.
2. Edit the settings near the top of the shell template: input descriptor,
   output filename, comma-separated variable names, coordinate files, first
   record's date/time, and output interval. Use names actually listed in your
   `.ctl`; availability depends on your CM1 output flags. The supplied selections
   and times are examples from an earlier case.
3. Update the coordinate files to match your simulation. The supplied horizontal
   grid is **1200 × 1200 at 25 m spacing**, and the vertical axis has **274 scalar
   levels**; neither is a universal CM1 grid. Check grid origins, spacing, units,
   level count, and heights. These scalar-level examples are unsuitable for fields
   on different vertical grids. Overriding coordinates does not regrid data or
   interpolate terrain-following fields to fixed physical heights.
4. For a 2D-only selection, set `zaxis_file=""`. For 3D fields, supply the matching
   vertical axis. Convert 2D and 3D selections separately. Give each group a distinct
   output filename.
5. Review the Slurm account, partition, resources, and time limit in the header.
   From the output directory, run `sbatch convert_to_netcdf.sh`. To run directly
   where CDO is available, use `bash convert_to_netcdf.sh`; the Slurm header is
   ignored in that mode. The script loads the Levante `cdo` module if CDO is absent.

The template explicitly replaces the time axis. Set its start to the first stored
record's time, including any elapsed simulation time since initialization, and
set its interval to the actual output interval (CM1's `tapfrq`). Check the resulting
coordinates, times, and selected variables before using the NetCDF file.
