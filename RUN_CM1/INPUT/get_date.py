# get_date.py

def read_namelist(file_path):
    # Initialize variables
    year = None
    month = None
    day = None
    hour = None
    minute = None
    second = None
    
    # Open the file and read line by line
    with open(file_path, 'r') as f:
        for line in f:
            # Strip whitespace and split on '='
            key_value = line.strip().split('=')
            if len(key_value) == 2:
                key = key_value[0].strip()
                value = key_value[1].strip().rstrip(',')  # Remove comma if present
                
                # Assign values based on key
                if key == 'year':
                    year = int(value)
                elif key == 'month':
                    month = int(value)
                elif key == 'day':
                    day = int(value)
                elif key == 'hour':
                    hour = int(value)
                elif key == 'minute':
                    minute = int(value)
                elif key == 'second':
                    second = int(value)
    
    return year, month, day, hour, minute, second

if __name__ == "__main__":
    file_path = 'namelist.input'  # Adjust the path as necessary
    year, month, day, hour, minute, second = read_namelist(file_path)

    # Print values to standard output (stdout)
    if all(val is not None for val in [year, month, day, hour, minute, second]):
        print(year, month, day, hour, minute, second)
    else:
        print("Error: Missing or incomplete datetime information in namelist.input")
