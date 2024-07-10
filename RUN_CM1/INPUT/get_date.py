# getDate.py

import configparser
import sys

def read_namelist(file_path):
    config = configparser.ConfigParser()
    config.read(file_path)

    # Extract values from namelist.input
    year = config.getint('model_switches', 'year')
    month = config.getint('model_switches', 'month')
    day = config.getint('model_switches', 'day')
    hour = config.getint('model_switches', 'hour')
    minute = config.getint('model_switches', 'minute')
    second = config.getint('model_switches', 'second')

    return year, month, day, hour, minute, second

if __name__ == "__main__":
    file_path = 'namelist.input'  # Adjust the path as necessary
    year, month, day, hour, minute, second = read_namelist(file_path)

    # Print values to standard output (stdout)
    print(year, month, day, hour, minute, second)
