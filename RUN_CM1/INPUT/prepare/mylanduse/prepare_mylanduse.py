"""Crop and resample an existing land-use NetCDF for a CM1 domain."""

from __future__ import annotations

import argparse
from pathlib import Path

from landuse_workflow import Landuse


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="Existing NetCDF containing landuse and x/y coordinates")
    parser.add_argument("output", type=Path, help="Target mylanduse.nc path")
    parser.add_argument("--center", nargs=2, type=float, required=True, metavar=("X", "Y"),
                        help="Domain center in Swiss LV03 or LV95 metres")
    parser.add_argument("--domain", nargs=2, type=float, required=True,
                        metavar=("WIDTH", "HEIGHT"), help="Domain size in metres")
    resolution = parser.add_mutually_exclusive_group()
    resolution.add_argument("--upsample", type=int, default=1,
                            help="Repeat each category into N x N finer cells")
    resolution.add_argument("--downsample", type=int, default=1,
                            help="Use modal category in N x N source cells")
    parser.add_argument("--border-index", type=int, default=7,
                        help="Land-use class assigned to the border (default: 7)")
    parser.add_argument("--border-width", type=int, default=4,
                        help="Border width in output cells; 0 disables it")
    args = parser.parse_args()

    if not args.source.is_file():
        parser.error(f"Source not found: {args.source}")
    if args.output.suffix != ".nc":
        parser.error("Output must end in .nc")
    if args.output.exists():
        parser.error(f"Output already exists: {args.output}")
    if args.upsample < 1 or args.downsample < 1 or args.border_width < 0:
        parser.error("Resampling factors must be positive and border width nonnegative")

    landuse = Landuse()
    landuse.open_landuse_dataset(str(args.source))
    landuse.crop_to_domain(coordinates=args.center, domain=args.domain)
    if args.upsample > 1:
        landuse.upsample_landuse(args.upsample)
    if args.downsample > 1:
        landuse.downsample_landuse(args.downsample)
    if args.border_width:
        landuse.set_border_index(args.border_index, args.border_width)
    print(f"Land-use shape (y, x): {landuse.lu.shape}")
    landuse.save_to_netcdf(args.output)


if __name__ == "__main__":
    main()
