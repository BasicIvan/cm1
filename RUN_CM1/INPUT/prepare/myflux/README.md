# Prepare `myflux.nc`

[`prepare_myflux.py`](prepare_myflux.py) calls the bundled [`flux_workflow.py`](flux_workflow.py). Supply a CO2 emissions grid, a CH4 emissions grid, a VPRM dataset with `GPP`, `RESP`, and `time`, and CO2 and CH4 hourly-profile CSVs with `dtm`. The workflow also expects the traffic, residential, services, industry, and agriculture sector variables and columns used by these inputs.

Run the command from the directory containing `prepare_myflux.py`. Set every source, time, grid-shape, and trim variable for **your** dataset. The script requires these values explicitly.

```sh
python3 prepare_myflux.py "$FLUX_SOURCE_DIR" "$CM1_INPUT_DIR/myflux.nc" \
  --co2 "$CO2_FILE" --ch4 "$CH4_FILE" --vprm "$VPRM_FILE" \
  --co2-profile "$CO2_PROFILE" --ch4-profile "$CH4_PROFILE" \
  --start "$START_HOUR" --end "$END_HOUR" \
  --shape "$NY" "$NX" --lat-trim "$LAT_TRIM" --lon-trim "$LON_TRIM"
```

File variables may be filenames inside `FLUX_SOURCE_DIR` or full source paths. Use `YYYY-MM-DDTHH` for both hours; the end hour is excluded. All time-dependent inputs must cover that interval. The workflow resizes arrays to `NY × NX` without reprojection or output coordinates, so inspect source coverage and orientation and choose trims before generating the file.

The output components are GPP, respiration, anthropogenic CO2, and anthropogenic CH4 in that order. The existing conversion factors and linear interpolation are retained. The writer produces float64 `flux(ny,nx,nt,npt)` with `npt=4` in `NETCDF4_CLASSIC`, without fill values. Check the output time count and the run's tracer configuration.
