"""Prepare CM1 terrain from an ASCII raster using the existing Swiss-topo writer."""

from __future__ import annotations

import argparse
from pathlib import Path

from terrain_workflow import swisstopoToNc


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path, help="Target myzs.nc path")
    parser.add_argument("--raster", type=Path, required=True,
                        help="Input ASCII terrain raster")
    parser.add_argument("--center", nargs=2, type=float, required=True,
                        metavar=("X", "Y"), help="Domain center in Swiss LV03 metres")
    parser.add_argument("--domain", nargs=2, type=float, required=True,
                        metavar=("WIDTH", "HEIGHT"), help="Domain size in metres")
    parser.add_argument("--smooth-sigma", type=float, help="Optional Gaussian smoothing in grid cells")
    parser.add_argument("--blend-border-width", type=int,
                        help="Optional border blend width in grid cells")
    args = parser.parse_args()

    output = args.output.resolve()
    if output.suffix != ".nc":
        parser.error("Output must end in .nc")
    if output.exists():
        parser.error(f"Output already exists: {output}")
    if not args.raster.is_file():
        parser.error(f"Raster not found: {args.raster}")
    if min(args.domain) <= 0:
        parser.error("Domain width and height must be positive")

    terrain = swisstopoToNc()
    terrain.loadDataFromAsc(str(args.raster))
    terrain.loadTopography(coordinates=list(args.center), domain=list(args.domain))
    if args.smooth_sigma is not None:
        terrain.smoothTopography(sigma=args.smooth_sigma)
    if args.blend_border_width is not None:
        terrain.blendTopoBordersToMedian(blend_width=args.blend_border_width)
    terrain.checkSteepness()
    print(f"Terrain shape (y, x): {terrain.topo.shape}")
    terrain.createNetCDF(output.name, output_dir=output.parent)
    print(f"Wrote {output}")


if __name__ == "__main__":
    main()
