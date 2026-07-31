## edvintb's dotfiles

### Setup Instructions

#### New machine

Clone the repository and use `setup.sh` as the single entry point:

```bash
git clone https://github.com/edvintb/dotfiles.git ~/.dotfiles
bash ~/.dotfiles/setup.sh
```

The script detects the platform before installing anything:

| Platform | Installation strategy | Requirements |
| --- | --- | --- |
| macOS arm64 or x86-64 | Native packages from `Brewfile`; tmux and Neovim included | Homebrew, Git, and network access |
| Linux x86-64 | Standalone tools under `~/.local`; optional source builds | curl, Git, zsh, and network access |
| Other platforms | Exits without installing | Not currently supported |

Both supported paths link the shared configuration, create a git-ignored
`secrets.sh` from the example when needed, and add GitHub to SSH `known_hosts`.

The Linux path additionally:

- Installs **oh-my-zsh** + the `zsh-autosuggestions` / `zsh-syntax-highlighting` plugins
- Downloads standalone binaries: **fzf**, **git-delta**, **gh**, **Claude Code**, **uv**, **Node.js** (via nvm)
- Installs the **Rust toolchain** (rustup) and the Rust CLI tools — tree-sitter CLI, fd, rg, bat, eza, sd, dust, zoxide, hyperfine, tokei, … — via `ubuntu-install/rust-tools-install.sh`

On Linux, tmux and Neovim source builds are opt-in:

```bash
bash ~/.dotfiles/setup.sh --tmux --nvim
```

These flags are unnecessary on macOS because the Brewfile installs both tools.
They are accepted there only so the same bootstrap command remains harmless.

#### Symlinks only

`symlink.sh` is the single source of truth for every dotfile symlink — it links
`.zshrc`, `.bashrc`, `.gitconfig`, `vimrc`, `claude/`, and the `~/.config` tool
configs. It backs up any pre-existing regular file to `<file>.backup` before
linking and skips any config not present in the repo. `setup.sh` calls this same
script, so the two never drift. Run it on its own to re-link without installing:

```bash
zsh ~/.dotfiles/symlink.sh
```

Run `symlink-work.sh` to additionally link `~/bin-work` from an optional
`.dotfiles-work/` checkout.

#### Mac

`setup.sh` detects macOS and uses Homebrew, supporting both Apple Silicon and
Intel Macs. It deliberately runs the macOS branch before any Linux download,
preventing incompatible binaries from being placed in `~/.local/bin`.

The direct commands remain available if you only want to rerun the package or
linking steps:

```bash
brew bundle --file=~/.dotfiles/Brewfile
zsh ~/.dotfiles/symlink.sh
```

- Use `bin/` for any scripts you want added to `$PATH`
- Put machine-specific env vars / secrets in `secrets.sh` — it's git-ignored and
  created from `secrets.sh.example`, and `init.sh` sources it for both bash and
  zsh (so real secrets never get committed)

#### Secrets

Never add credentials to tracked shell configuration. Put API tokens and
machine-specific private values in `~/.dotfiles/secrets.sh`. Only
`secrets.sh.example`, containing placeholder values, belongs in Git.


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

### Karabiner configuration

`karabiner/karabiner.json` defines one three-way Caps Lock rule:

- Tap Caps Lock for Escape.
- Hold Caps Lock while pressing another key for Left Control.
- Press Right Shift+Caps Lock for literal Caps Lock.

The tap decision uses a 250 ms timeout. The Right Shift chord is intentionally
listed before the general dual-role rule so the more specific mapping wins.
