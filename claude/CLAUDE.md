# Dotfiles — CLAUDE.md

## Repository Structure

This is a dotfiles repo managed via symlinks. Key directories:
- `bin/` — Personal scripts (linked to `~/bin-personal`)
- `ubuntu-install/` — Installation scripts for Linux environments
- `claude/` — Claude Code settings and this file
- `nvim/`, `tmux/`, `kitty/`, `lazygit/` — Tool configs (linked to `~/.config/`)
- `pod-setup.sh` — One-shot GKR pod environment setup

## GKR Pod Setup (megatron/brainatron/trainatron)

### Prerequisites (one-time per cluster)
These are stored on the shared `/mnt/home` filesystem and persist across pods:
1. **Git credentials**: `~/.netrc` with GitHub PAT (enables HTTPS git on all pods)
2. **SSH known_hosts**: `~/.ssh/known_hosts` with github.com keys
3. **Dotfiles clone**: `git clone https://github.com/edvintb/dotfiles.git /mnt/home/dotfiles`

### Full setup
Run `pod-setup.sh` on a fresh cluster to install everything:
```bash
gkr s pod-setup -p 1 -g 0 -C m --cmd "bash /mnt/home/dotfiles/pod-setup.sh"
```

This installs:
- **System packages**: zsh, tmux, neovim, fzf, git-delta, build tools
- **Dotfile symlinks**: .bashrc, .gitconfig, .vimrc, .claude/, .config/nvim, .config/tmux, bin-personal
- **Rust toolchain + CLI tools**: fd, rg, bat, eza, sd, xcp, dust, btm, procs, xh, tokei, hyperfine, zoxide
- **Node.js**: via nvm (v22)
- **GitHub CLI**: gh

### What persists on /mnt/home vs what needs reinstalling
- **Persists**: dotfiles, .netrc, .git-credentials, .ssh/, .local/bin (rust tools), .nvm/, .cargo/
- **Per-pod** (needs apt-get each time): zsh, tmux, neovim, fzf, git-delta, build-essential, gh
- **Per-pod** (from dotfiles symlinks): .bashrc, .config/*, bin-personal

### Quick pod command prefix for tools
If you just need basic tools on a throwaway pod without full setup:
```bash
apt-get update -qq && apt-get install -y -qq zsh tmux neovim fzf > /dev/null 2>&1 && source ~/.bashrc
```

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

### SSH Keys
- GitHub SSH key: `~/.ssh/reve_key` (symlinked to `~/.ssh/id_ed25519` for gkr-setup compatibility)

### Guidelines
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
