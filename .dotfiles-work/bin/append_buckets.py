#!/usr/bin/env python3
import requests
import sys
import csv

def lookup_md5s(md5s: str):
    """Sends a GET request, parses HTML, and prints it nicely."""
    url = f"http://localhost:5001/lookup/bucket?md5s={md5s}"

    try:
        response = requests.get(url)

        if response.status_code == 200:
            csv_data = response.text
            csv_reader = csv.DictReader(csv_data.splitlines())
            return csv_reader

        else:
            print(f"Request failed with status code: {response.status_code}")

    except requests.exceptions.RequestException as e:
        print(f"An error occurred: {e}")


def parse_args(args):
    if len(sys.argv) < 2:
        return sys.stdin

    file_path = sys.argv[1]

    if file_path == sys.stdout:
        print("output should be different from input")
        sys.exit(1)

    try:
        csv_file = open(file_path, 'r')
        return csv_file
    except FileNotFoundError:
        print(f"File not found: {file_path}")
        sys.exit(1)
    except csv.Error as e:
        print(f"Error parsing CSV file: {e}")
        sys.exit(1)

def main(csv_file):
    csv_reader = csv.DictReader(csv_file)
    new_fieldnames = csv_reader.fieldnames + ['bucket']
    csv_list = list(csv_reader)
    md5s = [row['md5'] for row in csv_list]
    md5s_str = ",".join(md5s)
    md5_lookup = lookup_md5s(md5s_str)
    md5_to_bucket = {row['md5']: row['bucket'] for row in md5_lookup}
    csv_writer = csv.DictWriter(sys.stdout, fieldnames=new_fieldnames)
    csv_writer.writeheader()
    for row in csv_list:
        row['bucket'] = md5_to_bucket[row['md5']]
        csv_writer.writerow(row)


if __name__ == "__main__":
    csv_file = parse_args(sys.argv)
    main(csv_file)
    csv_file.close()
