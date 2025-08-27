#!/usr/bin/env bash

# Parse command line arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 <source-bucket> <target-bucket>"
    echo "Example: $0 gs://my-source-bucket/ gs://my-target-bucket/"
    exit 1
fi

SOURCE_BUCKET="$1"
TARGET_BUCKET="$2"

# Ensure buckets end with /
if [[ ! "$SOURCE_BUCKET" =~ /$ ]]; then
    SOURCE_BUCKET="${SOURCE_BUCKET}/"
fi
if [[ ! "$TARGET_BUCKET" =~ /$ ]]; then
    TARGET_BUCKET="${TARGET_BUCKET}/"
fi

# List all directories and filter for hex-byte names
# The `ls -d` flag ensures only directories are listed
# for dir in $(gsutil ls -d "${SOURCE_BUCKET}"* | grep -E "${SOURCE_BUCKET}[0-9a-fA-F]{2}/$"); do
#   echo "Moving $dir to ${TARGET_BUCKET}"
#   gsutil mv "$dir" "${TARGET_BUCKET}"
# done
# 1. Get a list of all objects within the specific directories to move
# and pipe them into a single gsutil mv command.
# gsutil ls -d "${SOURCE_BUCKET}"* | grep -E "${SOURCE_BUCKET}[0-9a-fA-F]{2}/$" | xargs -n 1 gsutil -m mv -R {} "${TARGET_BUCKET}"

# Loop through each subdirectory matching the pattern
for dir in $(gsutil ls -d "${SOURCE_BUCKET}"*/); do
  # Check if the directory name matches the hexadecimal pattern
  if [[ "$dir" =~ ^${SOURCE_BUCKET}[0-9a-fA-F]{2}/$ ]]; then
    echo "Moving directory: $dir"
    gsutil -m mv -R "$dir" "${TARGET_BUCKET}"
  fi
done

echo "Script finished."

echo "Script finished."
