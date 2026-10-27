# Prepare `mylanduse.nc`

Start with a classified land-use NetCDF containing `landuse` and projected `x` and `y` coordinates. [`prepare_mylanduse.py`](prepare_mylanduse.py) crops and resamples its existing classes; it does not classify a raw land-cover product. Run it from the directory containing the script:

```sh
python3 prepare_mylanduse.py "$LANDUSE_SOURCE" "$CM1_INPUT_DIR/mylanduse.nc" \
  --center "$CENTER_X" "$CENTER_Y" \
  --domain "$DOMAIN_WIDTH_M" "$DOMAIN_HEIGHT_M"
```

Set the source and domain variables for **your** run. Domain width and height are in metres. The bundled [`landuse_workflow.py`](landuse_workflow.py) accepts Swiss LV03 or LV95 centers and crops a source grid with LV95 coordinates. For other coordinate systems, adapt its coordinate conversion and crop logic. Use `--upsample FACTOR` or `--downsample FACTOR` if the source resolution differs from the CM1 grid. The workflow applies a border class by default; set `--border-index` and `--border-width` for your run, or use `--border-width 0` to leave the source border unchanged.

Check the output categories, coordinate direction, geographic coverage, and horizontal shape against `myzs.nc` and the run's `nx` and `ny`. The writer retains the classified source dataset's metadata and uses xarray's NetCDF defaults.
