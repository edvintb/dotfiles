#!/usr/bin/env python3

import sys
import os
import tempfile
import shutil

def rename_csv_header_in_place(filepath, old_name, new_name):
    """
    Renames a single CSV header in-place.

    Args:
        filepath: Path to the CSV file.
        old_name: The old header name.
        new_name: The new header name.
    """

    try:
        # Create a temporary file
        temp_file_fd, temp_file_path = tempfile.mkstemp()
        header_changed = False
        
        with os.fdopen(temp_file_fd, 'wb') as temp_file:
            with open(filepath, 'rb') as original_file:
                # Read and modify the first line
                first_line = original_file.readline()
                decoded_line = first_line.decode('utf-8')
                headers = [h.strip() for h in decoded_line.split(',')]
                
                for i, header in enumerate(headers):
                    if header == old_name:
                        headers[i] = new_name
                        header_changed = True
                
                if not header_changed:
                    print(f"Header '{old_name}' not found.")
                    os.unlink(temp_file_path)
                    return False

                # Write the modified header to the temp file
                new_header_line = ','.join(headers) + '\n'
                temp_file.write(new_header_line.encode('utf-8'))
                
                # Copy the rest of the file
                shutil.copyfileobj(original_file, temp_file)
        
                # Replace the original file with the temp file
                shutil.move(temp_file_path, filepath)
                return True

    except FileNotFoundError:
        print(f"File not found: {filepath}")
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python rename_header.py <filepath> <old_name> <new_name>")
        sys.exit(1)

    filepath = sys.argv[1]
    old_name = sys.argv[2]
    new_name = sys.argv[3]

    rename_csv_header_in_place(filepath, old_name, new_name)
