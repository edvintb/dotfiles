#!/usr/bin/env python3

import sys

def rename_csv_header_in_place(filepath, old_name, new_name):
    """
    Renames a single CSV header in-place.

    Args:
        filepath: Path to the CSV file.
        old_name: The old header name.
        new_name: The new header name.
    """

    try:
        with open(filepath, 'r+b') as f:
            first_line = f.readline()
            decoded_line = first_line.decode('utf-8')
            headers = [h.strip() for h in decoded_line.split(',')]

            header_changed = False
            for i, header in enumerate(headers):
                if header == old_name:
                    headers[i] = new_name
                    header_changed = True
                    break  # Stop after finding and renaming the header

            if header_changed:
                new_header_line = ','.join(headers) + '\n'
                encoded_new_header = new_header_line.encode('utf-8')
                f.seek(0)
                f.write(encoded_new_header)
                f.truncate()
            else:
                print(f"Header '{old_name}' not found.")

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
