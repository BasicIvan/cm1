"""Flux calculations and CM1 NetCDF writer used by this portable recipe."""

from pathlib import Path

import numpy as np
import pandas as pd
import scipy.ndimage
import xarray as xr


class Myflux:

    def __init__(
        self,
        dir_path: str,
        bDate: tuple,
        eDate: tuple,
        co2_path: str,
        ch4_path: str,
        vprm_path: str,
        co2_timeprofile_path: str,
        ch4_timeprofile_path: str,
        lonTrim: int = 15,
        latTrim: int = 21,
        output_dir: str = ".",
    ) -> None:
        self.dir_path = Path(dir_path)
        self.output_dir = Path(output_dir)
        self.lonTrim = int(lonTrim)
        self.latTrim = int(latTrim)

        if self.lonTrim < 0 or self.latTrim < 0:
            raise ValueError("lonTrim and latTrim must be non-negative integers.")

        # Load anthropogenic data
        self.fluxData_CO2 = xr.open_dataset(self._input_path(co2_path))
        self.fluxData_CH4 = xr.open_dataset(self._input_path(ch4_path))
        self.timeFactorData_CO2 = pd.read_csv(
            self._input_path(co2_timeprofile_path), delimiter=","
        )
        self.timeFactorData_CH4 = pd.read_csv(
            self._input_path(ch4_timeprofile_path), delimiter=","
        )

        # Biogenic:
        self.vprm = xr.open_dataset(self._input_path(vprm_path))

        # Select date:
        self.bDate = bDate
        self.eDate = eDate

        self.sectors = ("traffic", "residential", "services", "industry", "agriculture")

        self.findIndices()
        self.convertToDatetime()

    def _input_path(self, path: str) -> Path:
        path = Path(path)
        return path if path.is_absolute() else self.dir_path / path

    def _trim_slices(self):
        lat_stop = -self.latTrim - 1 if self.latTrim else None
        lon_stop = -self.lonTrim if self.lonTrim else None
        return slice(self.latTrim, lat_stop), slice(self.lonTrim, lon_stop)

    def findIndices(self):
        # Select desired dates and times: date and time form: 'YYYY-MM-DD hh:mm:ss' (LT)
        byear, bmonth, bday, bhour = self.bDate
        eyear, emonth, eday, ehour = self.eDate
        # Find beginning and ending index (ib, ie) based on the selected date range
        self.ib = self.timeFactorData_CO2[
            self.timeFactorData_CO2["dtm"] == f"{byear}-{bmonth}-{bday} {bhour}:00:00"
        ].index.item()
        self.ie = self.timeFactorData_CO2[
            self.timeFactorData_CO2["dtm"] == f"{eyear}-{emonth}-{eday} {ehour}:00:00"
        ].index.item()
        dtm = self.vprm.time.values
        self.ibBio = np.where(
            dtm
            == np.datetime64(
                byear
                + "-"
                + bmonth
                + "-"
                + bday
                + "T"
                + bhour
                + ":00"
                + ":00.000000000"
            )
        )[0][0]
        self.ieBio = np.where(
            dtm
            == np.datetime64(
                eyear
                + "-"
                + emonth
                + "-"
                + eday
                + "T"
                + ehour
                + ":00"
                + ":00.000000000"
            )
        )[0][0]

    def convertToDatetime(self):
        # Convert the time columns into datetime for proper indexing
        self.timeFactorData_CO2["dtm"] = pd.to_datetime(self.timeFactorData_CO2["dtm"])
        self.timeFactorData_CH4["dtm"] = pd.to_datetime(self.timeFactorData_CH4["dtm"])

    @property
    def resp(self):
        """
        Returns resp(x,y) with selected date range, lat/lon trimmed.
        Also converts from umol m-2 s-1 to kg m-2 s-1
        """
        lat_slice, lon_slice = self._trim_slices()
        return (
            self.vprm.RESP.values[
                self.ibBio : self.ieBio,
                lat_slice,
                lon_slice,
            ]
            * 44e-09
            * 1.8  # respiration increased by factor 1.8
        )

    @property
    def gpp(self):
        lat_slice, lon_slice = self._trim_slices()
        return (
            self.vprm.GPP.values[
                self.ibBio : self.ieBio,
                lat_slice,
                lon_slice,
            ]
            * 44e-09
        )

    def spatialCO2(self, sector):
        lat_slice, lon_slice = self._trim_slices()
        return self.fluxData_CO2[f"CO2_{sector}"].values[
            lat_slice,
            lon_slice,
        ]

    def timeFactorsCO2(self, sector):
        return (
            self.timeFactorData_CO2[f"CO2_{sector}"]
            .iloc[self.ib : self.ie]
            .values[:, np.newaxis, np.newaxis]
        )

    @property
    def anthropogenicFLuxesCO2(self):
        sumArray = None
        for sector in self.sectors:
            # Access CO2 time factors and spatial flux data

            # Sum the results for CO2
            if sumArray is None:
                sumArray = self.timeFactorsCO2(sector) * self.spatialCO2(
                    sector
                )  # Initialize with first sector
            else:
                sumArray += self.timeFactorsCO2(sector) * self.spatialCO2(sector)

        return sumArray

    def spatialCH4(self, sector):
        lat_slice, lon_slice = self._trim_slices()
        return self.fluxData_CH4[f"CH4_{sector}"].values[
            lat_slice,
            lon_slice,
        ]

    def timeFactorsCH4(self, sector):
        return (
            self.timeFactorData_CH4[f"CH4_{sector}"]
            .iloc[self.ib : self.ie]
            .values[:, np.newaxis, np.newaxis]
        )

    @property
    def anthropogenicFLuxesCH4(self):
        sumArray = None
        for sector in self.sectors:
            # Access CH4 time factors and spatial flux data

            # Sum the results for CH4
            if sumArray is None:
                sumArray = self.timeFactorsCH4(sector) * self.spatialCH4(
                    sector
                )  # Initialize with first sector
            else:
                sumArray += self.timeFactorsCH4(sector) * self.spatialCH4(sector)
        return sumArray

    def interpolateToNewGrid(self, data: list, shape: list = [1200, 1200]) -> list:
        """
        Interpolate a list of input datasets to a new grid of the given shape.

        Parameters:
        - data: list of ndarray
            List of input arrays to be resampled. Each array should be 2D (y, x) or 3D (time, y, x).
        - shape: list
            Desired shape for the grid [newY, newX].

        Returns:
        - list of ndarray
            List of resampled data arrays with the new shape.
        """
        newY, newX = shape
        interpolated_data = []

        for dataset in data:

            # Determine zoom factors based on the dataset's dimensions
            if dataset.ndim == 3:  # For 3D data: (time, y, x)
                zoom_factors = (
                    1,  # No zoom on the time axis
                    newY / dataset.shape[1],  # y-axis scaling
                    newX / dataset.shape[2],  # x-axis scaling
                )
            elif dataset.ndim == 2:  # For 2D data: (y, x)
                zoom_factors = (
                    newY / dataset.shape[0],  # y-axis scaling
                    newX / dataset.shape[1],  # x-axis scaling
                )
            else:
                raise ValueError("Input data must be 2D or 3D.")

            # Perform interpolation
            interpolated_dataset = scipy.ndimage.zoom(
                dataset, zoom=zoom_factors, order=1
            )
            interpolated_data.append(interpolated_dataset)

        return interpolated_data

    def createNetCDF(self, ncName: str = "myflux.nc", shape: list = [1200, 1200]):
        if not ncName.endswith(".nc"):
            raise ValueError(
                f"The provided name '{ncName}' is invalid. It must end with 'nc'."
            )
        # Stack CO2 and CH4 into the new "npt" dimension
        stacked_flux = np.stack(
            self.interpolateToNewGrid(
                data=[
                    self.gpp,
                    self.resp,
                    self.anthropogenicFLuxesCO2,
                    self.anthropogenicFLuxesCH4,
                ],
                shape=shape,
            ),
            axis=-1,
        )  # Shape (time, ny, nx, npt)
        stacked_flux = np.transpose(
            stacked_flux, (1, 2, 0, 3)
        )  # Swap to yxtp. this will work with current CM1
        print(
            f"""The dimensions after transposing:
              {stacked_flux.shape}
              """
        )

        time_values = np.arange(
            1, stacked_flux.shape[0] + 1
        )  # Regular numpy array for time
        x_values = np.arange(stacked_flux.shape[1])
        y_values = np.arange(stacked_flux.shape[2])
        npt_values = np.arange(1, stacked_flux.shape[3] + 1)

        # Create the NetCDF file for the summed data
        ds = xr.Dataset(
            {
                "flux": (
                    ["ny", "nx", "nt", "npt"],  # Define the dimensions of flux
                    stacked_flux,  # The actual flux data array
                )
            },
        )

        self.output_dir.mkdir(parents=True, exist_ok=True)
        ds.to_netcdf(
            self.output_dir / ncName,
            format="NETCDF4_CLASSIC",
            encoding={
                "flux": {
                    "dtype": "float64",
                    "_FillValue": None,
                },
            },
        )


