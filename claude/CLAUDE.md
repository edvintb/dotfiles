1. Preferred Rust Tools (Performance Replacements)

## Core Tools (Significantly Faster)
- Use `fd` instead of `find` for file search
- Use `ripgrep` (rg) instead of `grep` for code search
- Use `dust` instead of `du` for disk usage
- Use `sd` instead of `sed` for find & replace
- Use `xcp` instead of `cp` for faster file copying with progress bars
- Use `bat` instead of `cat` for viewing files with syntax highlighting
- Use `eza` instead of `ls` for directory listings
- Use `tokei` for counting lines of code
- Use `hyperfine` for command benchmarking
- Use `bottom` (btm) instead of `top`/`htop`
- Use `procs` instead of `ps`
- Use `xh` instead of `curl` for HTTP requests
- Use `zoxide` instead of `cd` for smart directory navigation

## Guidelines
- A queryfile is a sqlite file with a specific structure. Use QueryFileWriter
  from ~/reve-training-data/common/queryfile.py when asked to write a queryfile.
  This will make sure we use the right structure. You can read either using
  sqlite3 cli or the QueryFileBackedList. After modifying or creating a .db
  file, use the qu cli tool to make sure it satisifes the criteria to be a
  queryfile.
- Give up and try different search if file is not found within 15 seconds
- All utilities installed in /mnt/home/.local/bin
- Move all .db files to /tmp before running any linear-time SQL queries.
  /mnt/data/ and /mnt/home interact poorly with sqlite.

2. UV Package Manager

## Usage
- Use `uvl` instead of `uv` for running commands
- `uvl` creates virtual environments in `/tmp/<project-name>/.venv` instead of the project directory
- `uvl` uses a shared cache at `/tmp/.uv-cache` for faster dependency resolution
- `uvl` automatically unsets VIRTUAL_ENV to avoid conflicts
- IMPORTANT: Always source ~/.bashrc before using uvl for faster installs

## Examples
- `source ~/.bashrc && uvl sync` - Sync dependencies
- `source ~/.bashrc && uvl run script.py` - Run a Python script
- `source ~/.bashrc && uvl add package` - Add a package to dependencies
