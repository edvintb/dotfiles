## edvintb's dotfiles

### Setup Instructions

#### New machine (Linux, macOS, or VM)

**`setup.sh` is the only script you need to run** — clone the repo and run it once:

```bash
git clone https://github.com/edvintb/dotfiles.git ~/.dotfiles
bash ~/.dotfiles/setup.sh --tmux --nvim
```

That single command does the whole setup in one pass — symlinking and secrets
bootstrap included, so you don't run anything else afterwards. On Linux x86-64,
tools install under `~/.local` (which persists on ephemeral hosts), and the
independent steps run in parallel. On macOS, the same script installs native
packages from the Brewfile before applying the shared configuration.

- Installs **oh-my-zsh** + the `zsh-autosuggestions` / `zsh-syntax-highlighting` plugins
- Downloads standalone binaries: **fzf**, **git-delta**, **gh**, **Claude Code**, **uv**, **Node.js** (via nvm), **tree-sitter** CLI
- Installs the **Rust toolchain** (rustup) and the Rust CLI tools — fd, rg, bat, eza, sd, dust, zoxide, hyperfine, tokei, … — via `ubuntu-install/rust-tools-install.sh`
- **Symlinks all dotfiles** into `$HOME` (by calling `symlink.sh`) and creates a git-ignored `secrets.sh` from the template
- Sets up `~/.ssh/known_hosts` for github.com

**tmux and neovim are opt-in** — they're built from source only when you pass
`--tmux` / `--nvim` (each installs its own apt build deps; `nv-build.sh` also
installs the Python `pip`/`venv` deps Mason needs). Plain `bash ~/.dotfiles/setup.sh`
installs everything *except* those two, so include the flags unless you already
have them.

`curl` and `zsh` are assumed present on the base image.

#### Symlinks only

`symlink.sh` is the single source of truth for every dotfile symlink — it links
`.zshrc`, `.bashrc`, `.gitconfig`, `vimrc`, `claude/`, and the `~/.config` tool
configs. It backs up any pre-existing regular file to `<file>.backup` before
linking and skips any config not present in the repo. `setup.sh` calls this same
script, so the two never drift. Run it on its own to re-link without installing:

```bash
bash ~/.dotfiles/symlink.sh
```

Run `symlink-work.sh` to additionally link `~/bin-work` from an optional
`.dotfiles-work/` checkout.

#### Mac

`setup.sh` detects macOS and uses Homebrew, supporting both Apple Silicon and
Intel Macs. The direct commands remain available if you only want to rerun the
macOS-specific steps:

```bash
brew bundle --file=~/.dotfiles/Brewfile
zsh ~/.dotfiles/symlink.sh
```

- Use `bin/` for any scripts you want added to `$PATH`
- Put machine-specific env vars / secrets in `secrets.sh` — it's git-ignored and
  created from `secrets.sh.example`, and `init.sh` sources it for both bash and
  zsh (so real secrets never get committed)


### Requirements

- Shell: [zsh](https://github.com/ohmyzsh/ohmyzsh/wiki/Installing-ZSH)
    - Shell Config Manger: [oh my zsh](https://github.com/ohmyzsh/ohmyzsh)
        - Suggestions: [autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
        - Highlighting: [syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
- Terminal Manager: [tmux](https://github.com/tmux/tmux)
- Editor: [nvim](https://github.com/neovim/neovim)
- Pager: [delta](https://github.com/dandavison/delta?tab=readme-ov-file)
- Conda: [miniforge](https://github.com/conda-forge/miniforge)


#### Command Line Tools

- [ripgrep](https://github.com/BurntSushi/ripgrep)
- [fzf](https://github.com/junegunn/fzf)
- [gh](https://github.com/cli/cli)


### Mac Setup

- Terminal Emulator: [kitty](https://sw.kovidgoyal.net/kitty/)
    - Font: [FiraCode Nerd Font](https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/FiraCode)
- Package Manager: [brew](https://brew.sh/)
- Window Manager: [AeroSpace](https://github.com/nikitabobko/AeroSpace)
- Keyboard Customizer: [Karabiner-Elements](https://karabiner-elements.pqrs.org)
- Night Shift: [flux](https://justgetflux.com/)

### `neovim` Setup

TODO: give overview


### `vim` Setup

A basic vim configuration is included with sensible defaults. The `symlink.sh` script creates a symlink for `~/.vimrc`.

**Features:**
- Line numbers with relative numbering
- Smart case-sensitive search
- 4-space indentation
- Mouse support
- Tmux integration
- Local customizations via `~/.vimrc_local`


### Alfred configuration

1. Set Cmd+Space to be the key to open the alfred window
2. Under Advanced, disable the ctrl key and force a US keyboard
3. Under Features->Universal Actions, disable Ctrl (required for the Caps Lock
   mapping: tap for Escape, hold for Control, Right Shift+Caps for Caps Lock)
4. Enable clipboard history
