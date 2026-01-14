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
- Give up and try different search if file is not found within 15 seconds
- All utilities installed in /mnt/home/.local/bin
