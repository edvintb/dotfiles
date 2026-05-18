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

### What persists on /mnt/home
Everything installs to `~/.local` (`/mnt/home/.local`) so it persists across pods:
- **~/.local/bin**: tmux, nvim, fzf, delta, gh (built from source or downloaded binaries)
- **~/.local/bin**: Rust CLI tools (fd, rg, bat, eza, sd, etc.)
- **~/.cargo/**: Rust toolchain
- **~/.nvm/**: Node.js
- **~/.netrc, ~/.git-credentials, ~/.ssh/**: Git/SSH credentials
- **~/dotfiles/**: This repo (symlinked to ~/.dotfiles)
- **Symlinks** (.bashrc, .config/*, bin-personal) point into /mnt/home/.dotfiles so they persist too

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
- All utilities installed in /mnt/home/.local/bin

## Git
- Git branch prefix: `edvin/`

## Google Cloud Storage
- Use `gcloud storage` instead of `gsutil` for all GCS operations
  - e.g. `gcloud storage rsync gs://bucket/path/ /local/path/`
  - e.g. `gcloud storage cp gs://bucket/path/file /local/path/`
  - e.g. `gcloud storage ls gs://bucket/path/`

## Reve V3 Resolutions
- Canonical aspect ratio → (width, height) table: `~/.claude/reve_v3_resolutions.md`
- Use these when snapping image dimensions for inference (already at ~4096 tokens / 64px patch)

## Repo Locations
- All repos are in ~ (home directory): reve-ml, reve-training-data,
  reve-training-data/common/reve-data-common, reve-dataloader, etc.

## 

## Queryfiles
- A queryfile is a sqlite file with a specific structure.
  To write a queryfile, use QueryFileWriter from ~/reve-training-data/common/queryfile.py. This will make sure we use the right structure.
  To iterate a queryfile in a script, use Dataloader from ~/reve-dataloader.
  To process rows, use datapipes. Pipes are in ~/reve-dataloader and
  ~/reve-ml. Try to use those, but write your own if you have to.
  Use ComposePipes and a sequence of pipes. Nesting pipes inside each other
  plays poorly with the dataloader parallelism.

- Queryfiles are sorted by MD5. This enables merge-join between two queryfiles without copying them to /tmp or building an index.

- Move large .db files to /tmp before running any linear-time SQL queries. /mnt/data/ and /mnt/home interact poorly with sqlite.

- To clean up a queryfile after manual edits (fix rowids, sort by MD5):
  ```
  qu repair <input>.db -o <output>.db && qu check <output>.db
  ```
  The output file must not already exist. Copy back to the original path when done.

### Using QueryFileWriter
Always check the output path at the very start of the script and raise early, before doing any work. This avoids wasting time on a long-running job only to crash at the write step:
```python
if os.path.exists(output_path):
    raise FileExistsError(f"Output file already exists: {output_path}")
```

### Input-output queryfile format
When asked to use "input-output format", refer to this example:
`/mnt/data/queryfiles/data-tasks/task13.1_user_multiref_w_labels.db`

Key principle: image-specific information goes in the JSON fields; shared/row-level information goes in regular columns.
- `input_images_json`: list of `{md5, bucket, extension, path, width, height, ...}` dicts — one entry per input/reference image
- `output_images_json`: list of `{md5, bucket, extension, path, width, height, ...}` dicts — one entry per output image
- Any metadata that applies to the whole row (e.g. prompt, label, score) is a regular column, not inside the JSON

### Common pipes
All importable from `reve_dataloader.datapipe`. More pipes are available — check `~/reve-dataloader/reve_dataloader/datapipe/` for the full list.
- `ComposePipes(pipes)` — chains pipes sequentially; the top-level datapipe passed to DataLoader should always be a ComposePipes
- `LoadImageFromPath(path_key, image_key)` — loads a PIL image from a GCS or local path in sample_dict
- `LoadImageFromMD5(md5_key, bucket_key, output_key)` — builds GCS path from md5+bucket, then loads image; composes LoadPathFromMD5 + LoadImageFromPath internally
- `LoadJson(json_keys)` — parses JSON string keys in sample_dict to Python objects; if json_keys=[] parses all keys ending in `_json`
- `ApplyPipesToKeys(pipes, keys)` — applies a sub-pipeline to a dict or list-of-dicts at the given keys; use this to process nested structures like output_images_json without manually nesting pipes

### Using DataLoader to iterate a queryfile in a script (non-training)
For offline annotation/processing scripts, use DataLoader with these settings:
```python
from reve_dataloader.dataloader import DataLoader
from reve_dataloader.collate import DoNotCollate

dataloader = DataLoader(
    queryfile=path_to_db,
    datapipe=ComposePipes([...]),
    batch_size=1,
    num_processes=8,          # parallel GCS downloads
    auto_repeat=False,        # finite iteration (not infinite training loop)
    sequential=True,          # process in md5 order
    random_seed=0,            # required when sequential=True
    collate_fn=DoNotCollate(), # get raw sample dicts, not collated tensors
    extra_keys_from_queryfile=["col1", "col2", ...],
)

for batch in dataloader:
    sample = batch[0]  # batch_size=1, so always index 0
    md5 = sample["md5"]   # comes as a hex string, not bytes
    bucket = sample["bucket"]
```

Key gotchas:
- `md5` is a hex string (not bytes) — no `.hex()` needed
- `sequential=True` requires `random_seed=0` explicitly, otherwise DataLoader raises
- `DoNotCollate` is needed when sample dicts contain PIL images or other non-tensor types
- Output queryfiles written from parallel workers won't be md5-sorted; run `qu repair` afterwards
- `ApplyPipesToKeys` drops the whole sample if any nested image load fails (no partial results)
- **Always use DataLoader (not ThreadPoolExecutor or manual GCS calls) when reading large queryfiles.** DataLoader uses multiple processes and saturates GCS bandwidth (~40 img/s). ThreadPoolExecutor with a shared GCS client is bottlenecked by connection pool contention and the GIL.
- **CPU-bound work (rendering, encoding) must use ProcessPoolExecutor, not ThreadPoolExecutor.** The GIL prevents true parallelism for CPU work in threads. Pass data between processes as raw bytes (e.g. `img.tobytes()` + mode + size), not PIL objects. Import heavy libraries (Pango, Cairo) inside the worker function so each process initialises them independently without fork issues.
- **When using ThreadPoolExecutor with GCS (or any heavyweight client), always use thread-local clients.** Constructing `storage.Client()` on every call is slow (auth + connection pool setup) and causes bursty throughput. Use `threading.local()` so each thread initialises once and reuses its client:
  ```python
  import threading
  _local = threading.local()
  def get_client():
      if not hasattr(_local, 'client'):
          _local.client = storage.Client()
      return _local.client
  ```

### JSONL WAL (write-ahead log) for long-running scripts
Any script that processes a large queryfile and writes results to GCS or another queryfile must include a JSONL WAL for resume support. The WAL records each completed item so the script can skip already-done work on restart.

Pattern:
```python
wal_path = output_path + ".wal.jsonl"

# On startup: load completed items from WAL
done = set()
if os.path.exists(wal_path):
    with open(wal_path) as f:
        for line in f:
            entry = json.loads(line)
            done.add(entry["md5"])

# During processing: append each completed item
with open(wal_path, "a") as wal:
    for item in process(...):
        wal.write(json.dumps({"md5": item.md5, ...}) + "\n")
        wal.flush()

# On success: delete the WAL
os.remove(wal_path)
```

Resume logic must happen **before** the DataLoader is constructed, so that the temp queryfile passed to DataLoader only contains unprocessed items. This avoids re-downloading and re-rendering already-done crops.


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
