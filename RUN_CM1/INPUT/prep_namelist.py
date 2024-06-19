#!/usr/bin/env python3

from argparse import ArgumentParser

infile = 'namelist.input'

parser = ArgumentParser()
parser.add_argument("run_time", help="time interval for restart jobs")
parser.add_argument("num_files", help="number of restart jobs")

args = parser.parse_args()

run_time = float(args.run_time)
num_files = int(args.num_files)

def update_switch(namelist_content, new_value):
    # Find and replace irst, rstnum, run_time, and rstfrq
    lines = namelist_content.split('\n')
    for i, line in enumerate(lines):
        if line.strip().startswith("run_time ="):
            lines[i] = f" run_time = {run_time},"
        if line.strip().startswith("rstfrq ="):
            lines[i] = f" rstfrq = {run_time},"
        if line.strip().startswith("irst      ="):
            if new_value ==0: lines[i] = " irst      =  0,"
            else: lines[i] = " irst      =  1,"
        if line.strip().startswith("rstnum    ="):
            lines[i] = f" rstnum    =  {new_value},"
            break
    return '\n'.join(lines)

def main():
    original_file = "namelist.input"

    with open(original_file, 'r') as f:
        original_content = f.read()

    for i in range(num_files):
        updated_content = update_switch(original_content, i)
        new_filename = f"namelist.input{i:02}"
        
        with open(new_filename, 'w') as new_f:
            new_f.write(updated_content)

if __name__ == "__main__":
    main()

