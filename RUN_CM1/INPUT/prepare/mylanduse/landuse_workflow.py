"""Land-use cropping and resampling methods used by this portable recipe."""

from pathlib import Path

import numpy as np
import scipy.stats
import xarray as xr


class Landuse:
    def __init__(self, filepath: str | None = None):
        self.ds = None
        self.lu = None
        if filepath is not None:
            self.open_landuse_dataset(filepath)

    @staticmethod
    def _refined_cell_center_coords(values: np.ndarray, factor: int) -> np.ndarray:
        """Split each cell-center coordinate into factor finer cell centers."""
        values = np.asarray(values, dtype=float)
        if values.size < 2:
            raise ValueError("At least two coordinates are required for upsampling.")

        spacing = float(np.nanmedian(np.diff(values)))
        fine_spacing = spacing / factor
        offsets = (np.arange(factor) - (factor - 1) / 2) * fine_spacing
        return (values[:, None] + offsets[None, :]).reshape(-1)

    @staticmethod
    def _to_lv95(coordinates: list[float] | tuple[float, float]) -> tuple[float, float]:
        """
        Convert old Swiss LV03 coordinates to LV95 when needed.

        An LV03 center is converted by adding the Swiss LV95 offsets.
        """
        x, y = coordinates
        if x < 1_000_000 and y < 1_000_000:
            return x + 2_000_000, y + 1_000_000
        return x, y

    @staticmethod
    def domain_bounds(
        coordinates: list[float] | tuple[float, float],
        domain: list[float] | tuple[float, float],
    ) -> tuple[float, float, float, float]:
        cx, cy = Landuse._to_lv95(coordinates)
        dx, dy = domain[0] / 2, domain[1] / 2
        return cx - dx, cx + dx, cy - dy, cy + dy

    def _require_landuse(self):
        if self.lu is None:
            raise RuntimeError("Landuse not loaded. Call open_landuse_dataset first.")

    def crop_to_domain(
        self,
        coordinates: list[float] | tuple[float, float],
        domain: list[float] | tuple[float, float],
    ) -> xr.DataArray:
        """
        Crop landuse to a Swiss-coordinate box.

        The center may be LV03 or LV95; domain is the full size in metres.
        """
        self._require_landuse()
        x_min, x_max, y_min, y_max = self.domain_bounds(coordinates, domain)

        x_mask = (self.lu.x >= x_min) & (self.lu.x <= x_max)
        y_mask = (self.lu.y >= y_min) & (self.lu.y <= y_max)

        x_idx = np.where(x_mask.values)[0]
        y_idx = np.where(y_mask.values)[0]
        if len(x_idx) == 0 or len(y_idx) == 0:
            raise ValueError(
                "Requested domain does not overlap the landuse file. "
                f"Bounds are x={x_min:g}..{x_max:g}, y={y_min:g}..{y_max:g}."
            )

        self.lu = self.lu.isel(
            y=slice(y_idx.min(), y_idx.max() + 1),
            x=slice(x_idx.min(), x_idx.max() + 1),
        )
        if self.ds is not None and "landuse" in self.ds:
            self.ds = self.ds.isel(
                y=slice(y_idx.min(), y_idx.max() + 1),
                x=slice(x_idx.min(), x_idx.max() + 1),
            )
            self.lu = (
                self.ds.landuse.isel(band=0)
                if "band" in self.ds.landuse.dims
                else self.ds.landuse
            )
        else:
            self._sync_dataset_from_lu()
        return self.lu

    def set_border_index(
        self,
        index: int = 7,
        border_width: int = 4,
    ) -> xr.DataArray:
        """Set a constant landuse class on all four borders."""
        self._require_landuse()
        if border_width < 0:
            raise ValueError("border_width must be >= 0.")
        if border_width == 0:
            return self.lu

        modified = self.lu.copy(deep=True)
        values = modified.values.copy()
        values[:border_width, :] = index
        values[-border_width:, :] = index
        values[:, :border_width] = index
        values[:, -border_width:] = index
        modified.values = values
        self.lu = modified

        if self.ds is not None and "landuse" in self.ds:
            data = self.ds["landuse"].values.copy()
            attrs = self.ds["landuse"].attrs
            encoding = self.ds["landuse"].encoding
            if data.ndim == 3:
                data[0, :, :] = values
            elif data.ndim == 2:
                data[:, :] = values
            else:
                raise ValueError(f"Expected 2D or 3D landuse data, got {data.ndim}D.")
            self.ds["landuse"] = (self.ds["landuse"].dims, data)
            self.ds["landuse"].attrs = attrs
            self.ds["landuse"].encoding = encoding
            self.lu = (
                self.ds.landuse.isel(band=0)
                if "band" in self.ds.landuse.dims
                else self.ds.landuse
            )
        else:
            self._sync_dataset_from_lu()
        return self.lu

    def _sync_dataset_from_lu(self):
        old_ds = self.ds
        if self.ds is None:
            self.ds = self.lu.to_dataset(name="landuse").expand_dims(band=[1])
            return

        ds_attrs = old_ds.attrs
        attrs = old_ds["landuse"].attrs
        encoding = old_ds["landuse"].encoding
        band_values = old_ds["band"].values if "band" in old_ds.coords else [1]

        self.ds = self.lu.to_dataset(name="landuse").expand_dims(band=[1])
        self.ds = self.ds.assign_coords(band=band_values[:1])
        self.ds.attrs = ds_attrs
        self.ds["landuse"].attrs = attrs
        self.ds["landuse"].encoding = encoding

        for name, da in old_ds.data_vars.items():
            if name == "landuse":
                continue
            if "x" in da.dims or "y" in da.dims:
                continue
            self.ds[name] = da

    def downsample_landuse(self,
        factor: int = 4,
    ) -> xr.DataArray:
        """
        Downsamples a land use DataArray using mode aggregation over blocks.

        Parameters:
            landuse_da : xr.DataArray
                The input land use data (2D, with dimensions y and x).
            factor : int
                Downsampling factor (e.g., 4 = 100 m if original is 25 m).
            save_path : str, optional
                If given, the downsampled data will be saved to this NetCDF path.

        Returns:
            xr.DataArray
                The downsampled land use data.
        """
        self._require_landuse()
        # Convert to numpy and get shape
        data = self.lu.values
        ny, nx = data.shape

        # Ensure dimensions are divisible by factor
        ny_trim = ny - (ny % factor)
        nx_trim = nx - (nx % factor)
        data_trimmed = data[:ny_trim, :nx_trim]

        # Reshape and compute mode
        blocks = data_trimmed.reshape(
            ny_trim // factor, factor, nx_trim // factor, factor
        )
        blocks = blocks.transpose(0, 2, 1, 3).reshape(
            ny_trim // factor, nx_trim // factor, -1
        )
        data_downsampled = scipy.stats.mode(blocks, axis=2)[0].squeeze()

        # Compute new coordinates
        x_vals = self.lu.x.values[:nx_trim].reshape(-1, factor)
        y_vals = self.lu.y.values[:ny_trim].reshape(-1, factor)
        new_x = x_vals.mean(axis=1)
        new_y = y_vals.mean(axis=1)

        # Create downsampled DataArray
        self.lu = xr.DataArray(
            data_downsampled,
            coords={"y": new_y, "x": new_x},
            dims=("y", "x"),
            name=self.lu.name,
            attrs=self.lu.attrs,
        )
        self._sync_dataset_from_lu()
        return self.lu

    def upsample_landuse(
        self,
        factor: int = 2,
    ) -> xr.DataArray:
        """
        Upsample categorical land-use classes by splitting each cell.

        This uses nearest-neighbor repetition, which preserves class labels. For
        example, factor=2 converts a 25 m grid to 12.5 m and doubles both grid
        dimensions.
        """
        self._require_landuse()
        if factor < 1 or int(factor) != factor:
            raise ValueError("factor must be a positive integer.")
        factor = int(factor)
        if factor == 1:
            return self.lu

        data_upsampled = np.repeat(
            np.repeat(self.lu.values, factor, axis=0),
            factor,
            axis=1,
        )
        new_x = self._refined_cell_center_coords(self.lu.x.values, factor)
        new_y = self._refined_cell_center_coords(self.lu.y.values, factor)

        self.lu = xr.DataArray(
            data_upsampled,
            coords={"y": new_y, "x": new_x},
            dims=("y", "x"),
            name=self.lu.name,
            attrs=self.lu.attrs,
        )
        self._sync_dataset_from_lu()
        print(
            f"Landuse upsampled by factor {factor}: "
            f"{self.lu.sizes['y']} (y), {self.lu.sizes['x']} (x)"
        )
        return self.lu

    def upscale_landuse(self, factor: int = 2) -> xr.DataArray:
        """Alias for upsample_landuse."""
        return self.upsample_landuse(factor=factor)

    def save_to_netcdf(self, save_path):
        self._require_landuse()
        save_path = Path(save_path)
        save_path.parent.mkdir(parents=True, exist_ok=True)
        self.ds.to_netcdf(save_path)
        print(f"Saved landuse to: {save_path}")

    def open_landuse_dataset(self,filepath):
        # Open the dataset and extract land-use
        self.ds = xr.open_dataset(filepath)
        if "band" in self.ds.landuse.dims:
            self.lu = self.ds.landuse.isel(band=0)
        else:
            self.lu = self.ds.landuse
        return self.lu

