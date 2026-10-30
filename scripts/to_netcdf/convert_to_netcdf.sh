#!/bin/bash
#SBATCH --job-name=cm1_to_netcdf
#SBATCH --partition=compute
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=0
#SBATCH --time=08:00:00
#SBATCH --account=bb1096
#SBATCH --output=cm1_to_netcdf_%j.out
#SBATCH --error=cm1_to_netcdf_%j.err

set -euo pipefail

# Edit these settings for your case. Paths are relative to the working directory.
# Submit from the directory containing the .ctl and binary .dat output files.
control_file="cm1out_s.ctl"
output_file="cm1out_s_winds.nc"
variables="u_tm,v_tm,w_tm,winterp"  # Comma-separated names present in the .ctl.
grid_file="cm1_grid.txt"
zaxis_file="cm1_zaxis.txt"          # Set to "" for 2D-only selections.
start_date="2021-07-21"            # Date/time of the FIRST stored output record.
start_time="17:00:00"
output_interval="10min"           # Must match the stored output interval.

# Load CDO on Levante if it is not already available.
if ! command -v cdo >/dev/null 2>&1; then
    module load cdo
fi

for input_file in "$control_file" "$grid_file"; do
    if [[ ! -f "$input_file" ]]; then
        echo "Missing input: $input_file" >&2
        exit 1
    fi
done

zaxis_options=()
if [[ -n "$zaxis_file" ]]; then
    if [[ ! -f "$zaxis_file" ]]; then
        echo "Missing vertical axis: $zaxis_file" >&2
        exit 1
    fi
    zaxis_options=("-setzaxis,$zaxis_file")
fi

# CDO applies operators from right to left: import, select, then set coordinates.
# Select 2D and 3D fields separately; only the latter need the vertical axis.
cdo -f nc4 \
    "${zaxis_options[@]}" \
    "-setgrid,$grid_file" \
    "-settaxis,$start_date,$start_time,$output_interval" \
    "-selname,$variables" \
    -import_binary "$control_file" "$output_file"

# ----------------------------------------------------------------------
# Commented examples: copy a block into the settings above, then edit it.
# All names below come from the former case-specific conversion scripts;
# your .ctl may contain a different set of variables.
# ----------------------------------------------------------------------

# Winds (3D):
# variables="u_tm,v_tm,w_tm,winterp"
# output_file="cm1out_s_winds.nc"
# zaxis_file="cm1_zaxis.txt"

# Thermodynamics (3D):
# variables="th,th_tm,rho_tm,qv_tm"
# output_file="cm1out_s_thermo.nc"
# zaxis_file="cm1_zaxis.txt"

# Passive tracers (3D):
# variables="ptco2_tm,ptco2_ptco2,w_ptco2"
# output_file="cm1out_s_tracers.nc"
# zaxis_file="cm1_zaxis.txt"

# Turbulence (3D):
# variables="tke_sg,u_u,v_v,w_w"
# output_file="cm1out_s_turb.nc"
# zaxis_file="cm1_zaxis.txt"

# Variances and covariances (3D):
# variables="th_th,w_th,qv_qv,w_qv,u_w,v_w,u_th"
# output_file="cm1out_s_var.nc"
# zaxis_file="cm1_zaxis.txt"

# Surface and other 2D fields (no vertical-axis replacement):
# variables="cpc,cph,thflux,qvflux,tsk,cd,ch,cq,tlh,zs,xland,lu,mavail,tmn,hfx,qfx,gsw,glw,tml,hml,huml,hvml,lwupt,lwdnt,lwupb,lwdnb,swupt,swdnt,swupb,swdnb,lwcf,swcf,coszen,u10,v10,s10,t2,q2,znt,ust,stau,tst,qst,hpbl,zol,mol,br,psim,psih,psiq,fm,fh,qsfc,wspd"
# output_file="cm1out_s_2d.nc"
# zaxis_file=""
