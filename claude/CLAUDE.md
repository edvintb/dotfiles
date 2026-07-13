# Dotfiles — CLAUDE.md

## Script Style

- Always time each major section of a script (use `time.time()`) and print elapsed at the end of each section.
- Include comprehensive progress reporting: for any loop over large data, print progress every 5–10 seconds with count, percentage, rows/s, and ETA.

## Repository Structure

This is a dotfiles repo managed via symlinks. Key directories:
- `bin/` — Personal scripts (linked to `~/bin-personal`)
- `ubuntu-install/` — Installation scripts for Linux environments
- `claude/` — Claude Code settings and this file
- `nvim/`, `tmux/`, `kitty/`, `lazygit/` — Tool configs (linked to `~/.config/`)
- `setup.sh` — One-shot environment setup for local machines and VMs

## 1. Preferred Rust Tools (Performance Replacements)

### Core Tools (Significantly Faster)
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

## Git
- Git branch prefix: `edvin/`

## Google Cloud Storage
- Use `gcloud storage` instead of `gsutil` for all GCS operations
  - e.g. `gcloud storage rsync gs://bucket/path/ /local/path/`
  - e.g. `gcloud storage cp gs://bucket/path/file /local/path/`
  - e.g. `gcloud storage ls gs://bucket/path/`

## 2. UV Package Manager

### Usage
- Use `uvl` instead of `uv` for running commands
- `uvl` creates virtual environments in `/tmp/<project-name>/.venv` instead of the project directory
- `uvl` uses a shared cache at `/tmp/.uv-cache` for faster dependency resolution
- `uvl` automatically unsets VIRTUAL_ENV to avoid conflicts
- IMPORTANT: Always source ~/.bashrc before using uvl for faster installs

### Examples
- `source ~/.bashrc && uvl sync` - Sync dependencies
- `source ~/.bashrc && uvl run script.py` - Run a Python script
- `source ~/.bashrc && uvl add package` - Add a package to dependencies

## 3. Git Stack (Branch Stacking Tool)

### Overview
`git stack` is a custom CLI (`~/bin-personal/git-stack`) for stacking multiple feature branches onto a local branch. Each feature branch gets its own PR against main, and the stack is rebuilt when PRs merge.

### Commands
- `git stack init [base]` — Create/reset stack from base branch (default: main)
- `git stack add <branch>` — Merge a feature branch onto the stack
- `git stack drop <branch>` — Remove a branch and rebuild
- `git stack pick <branch> [commits...]` — Create branch from base, cherry-pick commits, add to stack
- `git stack depends <branch> <dep1> [dep2...]` — Set branch dependencies (for PR descriptions)
- `git stack rebase` — Fetch base, drop merged branches, rebuild
- `git stack sync` — Rebase all branches onto base, force-push, rebuild
- `git stack rebuild` — Rebuild stack from scratch (same branch list)
- `git stack status` — Show branches in the stack with dependency info
- `git stack pr [branch]` — Create GitHub PRs with "Depends on #X" in body
- `git stack log` — Show stack commits vs base

### Details
- State stored in `.git/stack-meta/` (per-repo, not committed): branches, base, depends
- Stack branch is always called `stack`
- Uses `--no-ff` merges so each feature is a distinct merge commit
- `git stack pr` uses `gh` CLI — pushes branch and creates PR with `--fill`
- `git stack rebase` auto-detects which branches have been merged into base
- `git stack sync` uses `--force-with-lease` when pushing rebased branches
- Dependencies tracked in `.git/stack-meta/depends` (format: `branch:dep1,dep2`)
- Designed for fork workflows where you can't push to upstream — all PRs target main

## Podchat iOS Project

When I say "build":
- **Just build** — run `xcodebuild` and report success/errors
- **Don't start simulator** — leave that for you to do manually via Xcode
- **Don't install/launch** — only build the binary
