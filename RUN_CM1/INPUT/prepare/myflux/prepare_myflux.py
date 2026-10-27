"""Prepare CM1 flux forcing from anthropogenic and VPRM source files."""

from __future__ import annotations

import argparse
from datetime import datetime
from pathlib import Path

from flux_workflow import Myflux


def hour_tuple(value: str) -> tuple[str, str, str, str]:
    dt = datetime.strptime(value, "%Y-%m-%dT%H")
    return dt.strftime("%Y"), dt.strftime("%m"), dt.strftime("%d"), dt.strftime("%H")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source_dir", type=Path, help="Directory containing the five source files")
    parser.add_argument("output", type=Path, help="Target myflux.nc path")
    parser.add_argument("--start", required=True, help="First hour, YYYY-MM-DDTHH")
    parser.add_argument("--end", required=True, help="Exclusive end hour, YYYY-MM-DDTHH")
    parser.add_argument("--shape", nargs=2, type=int, required=True,
                        metavar=("NY", "NX"), help="Target horizontal shape")
    parser.add_argument("--lat-trim", type=int, required=True,
                        help="Leading rows to trim; workflow removes one more trailing row")
    parser.add_argument("--lon-trim", type=int, required=True,
                        help="Columns to trim from both sides of source grids")
    parser.add_argument("--co2", required=True, help="CO2 emissions NetCDF filename or path")
    parser.add_argument("--ch4", required=True, help="CH4 emissions NetCDF filename or path")
    parser.add_argument("--vprm", required=True, help="VPRM NetCDF filename or path")
    parser.add_argument("--co2-profile", required=True, help="CO2 time-profile CSV filename or path")
    parser.add_argument("--ch4-profile", required=True, help="CH4 time-profile CSV filename or path")
    args = parser.parse_args()

    output = args.output.resolve()
    if output.suffix != ".nc":
        parser.error("Output must end in .nc")
    if output.exists():
        parser.error(f"Output already exists: {output}")
    if min(args.shape) < 1 or min(args.lat_trim, args.lon_trim) < 0:
        parser.error("Shape must be positive and trims must be nonnegative")
    try:
        start, end = hour_tuple(args.start), hour_tuple(args.end)
    except ValueError:
        parser.error("Start and end must use YYYY-MM-DDTHH")
    if start >= end:
        parser.error("End hour must be after start hour")
    for name in (args.co2, args.ch4, args.vprm, args.co2_profile, args.ch4_profile):
        path = Path(name)
        path = path if path.is_absolute() else args.source_dir / path
        if not path.is_file():
            parser.error(f"Source not found: {path}")

    flux = Myflux(
        dir_path=str(args.source_dir), bDate=start, eDate=end,
        co2_path=args.co2, ch4_path=args.ch4, vprm_path=args.vprm,
        co2_timeprofile_path=args.co2_profile,
        ch4_timeprofile_path=args.ch4_profile,
        latTrim=args.lat_trim, lonTrim=args.lon_trim,
        output_dir=str(output.parent),
    )
    flux.createNetCDF(ncName=output.name, shape=list(args.shape))
    print(f"Wrote {output}")


if __name__ == "__main__":
    main()
