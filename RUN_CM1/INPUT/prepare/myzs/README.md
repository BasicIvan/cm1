# Prepare `myzs.nc`

Use [`prepare_myzs.py`](prepare_myzs.py) with an ASCII elevation raster that covers your CM1 domain. The script requires the source file, domain center, full domain width and height, and destination file. Run it from the directory containing the script:

```sh
python3 prepare_myzs.py "$CM1_INPUT_DIR/myzs.nc" \
  --raster "$ELEVATION_RASTER" \
  --center "$CENTER_X" "$CENTER_Y" \
  --domain "$DOMAIN_WIDTH_M" "$DOMAIN_HEIGHT_M"
```

Set every variable to a value for **your** run; no source raster or domain is assumed. This workflow currently expects Swiss LV03 coordinates in metres. For another coordinate system, adapt and verify the raster-loading and crop steps before using the output. The cropped raster must have no NoData cells. Review the printed shape and steepness; `--smooth-sigma` and `--blend-border-width` are available when smoothing or border blending is needed.

The bundled [`terrain_workflow.py`](terrain_workflow.py) keeps the tested NetCDF settings: `NETCDF4_CLASSIC`, float64 without fill values, and `dx(one)`, `x(nx)`, `y(ny)`, `myzs(nx,ny)`. The writer assumes a square crop because it assigns a `(y,x)` raster array to `(nx,ny)`; check orientation before using a rectangular domain.
