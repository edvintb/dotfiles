#!/usr/bin/env bash
# nvim-deps.sh — install everything this Neovim *config* needs, then bootstrap it.
#
# nv-build.sh builds the neovim binary. This script installs the external
# programs the plugins in lua/config/lazy.lua shell out to, and then runs the
# headless bootstrap (lazy sync → treesitter parsers → mason servers).
#
# It is idempotent: every step checks for the tool first, so re-running it on a
# provisioned machine is a fast no-op.
#
# Usage: nvim-deps.sh [--tex] [--no-bootstrap] [--skip <tool>[,<tool>...]]
#
# Supported platforms: macOS (Homebrew), Linux with apt / dnf / pacman.

set -e

PREFIX="$HOME/.local"
LOCAL_BIN="$PREFIX/bin"
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"

# nvim-treesitter `main` shells out to the tree-sitter CLI to generate and
# compile every parser; the README pins the floor at 0.26.1.
TREE_SITTER_MIN="0.26.1"

WITH_TEX=false
BOOTSTRAP=true
SKIP=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --tex) WITH_TEX=true; shift ;;
        --no-bootstrap) BOOTSTRAP=false; shift ;;
        --skip) SKIP="$2"; shift 2 ;;
        -h|--help)
            sed -n '2,14p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'
            exit 0
            ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

mkdir -p "$LOCAL_BIN"
export PATH="$LOCAL_BIN:$HOME/.cargo/bin:$PATH"

SECONDS=0
log()  { echo "[+${SECONDS}s] $*"; }
skip() { case ",$SKIP," in *",$1,"*) return 0 ;; *) return 1 ;; esac; }
have() { command -v "$1" > /dev/null 2>&1; }

MISSING=()
note_missing() { MISSING+=("$1"); }

# -----------------------------------------------------------------------------
# 0. Platform detection
# -----------------------------------------------------------------------------
OS="$(uname -s)"
ARCH="$(uname -m)"

SUDO=""
if [ "$(id -u)" -ne 0 ] && have sudo; then
    SUDO="sudo"
fi

PKG=""
case "$OS" in
    Darwin)
        if have brew; then PKG=brew
        elif [ -x /opt/homebrew/bin/brew ]; then PKG=brew; export PATH="/opt/homebrew/bin:$PATH"
        elif [ -x /usr/local/bin/brew ]; then PKG=brew; export PATH="/usr/local/bin:$PATH"
        else
            echo "Homebrew is required on macOS: https://brew.sh" >&2
            exit 1
        fi
        ;;
    Linux)
        if have apt-get;   then PKG=apt
        elif have dnf;     then PKG=dnf
        elif have pacman;  then PKG=pacman
        else
            echo "No supported package manager found (apt/dnf/pacman)." >&2
            echo "Install the deps listed in this script by hand, then re-run with --skip." >&2
            exit 1
        fi
        ;;
    *)
        echo "Unsupported OS: $OS" >&2
        exit 1
        ;;
esac

echo "============================================"
echo "  Neovim config dependencies"
echo "  ${OS} ${ARCH} — package manager: ${PKG}"
echo "============================================"

# Install a list of package-manager packages. Names differ per distro, so each
# caller passes the name for every manager it supports.
pkg_install() {
    case "$PKG" in
        brew)   brew install "$@" ;;
        apt)    $SUDO apt-get install -o DPkg::Lock::Timeout=300 -y "$@" ;;
        dnf)    $SUDO dnf install -y "$@" ;;
        pacman) $SUDO pacman -S --needed --noconfirm "$@" ;;
    esac
}

if [ "$PKG" = apt ]; then
    log ">>> apt-get update"
    $SUDO apt-get update -o DPkg::Lock::Timeout=300 -qq
fi

# -----------------------------------------------------------------------------
# 1. Build toolchain + archive tools
#    nvim-treesitter compiles each parser with a C/C++ compiler; mason downloads
#    and unpacks prebuilt archives; lazy.nvim clones over git+curl.
# -----------------------------------------------------------------------------
log ">>> Core toolchain (compiler, git, curl, unzip)"
case "$PKG" in
    brew)   pkg_install git curl ;;   # Xcode CLT supplies cc/make/unzip/tar
    apt)    pkg_install build-essential git curl unzip wget tar gzip ;;
    dnf)    pkg_install gcc gcc-c++ make git curl unzip wget tar gzip ;;
    pacman) pkg_install base-devel git curl unzip wget tar gzip ;;
esac

# -----------------------------------------------------------------------------
# 2. tree-sitter CLI (>= 0.26.1) — required by nvim-treesitter `main`
#
#    Upstream's prebuilt linux-x64 binary is built against glibc 2.39, which is
#    newer than Debian 12 / Ubuntu 22.04 ship. So: use the prebuilt binary when
#    the host glibc is new enough, otherwise build from source with cargo. That
#    build needs libclang (bindgen), which is why libclang lands here and not in
#    the generic toolchain section.
# -----------------------------------------------------------------------------
version_ge() { [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -1)" = "$2" ]; }

ts_ok() {
    have tree-sitter || return 1
    local v
    v="$(tree-sitter --version 2>/dev/null | awk '{print $2}')" || return 1
    version_ge "$v" "$TREE_SITTER_MIN"
}

install_tree_sitter_from_source() {
    log "    building tree-sitter-cli from source (host glibc too old for the prebuilt binary)"
    case "$PKG" in
        apt)    pkg_install libclang-dev ;;
        dnf)    pkg_install clang-devel ;;
        pacman) pkg_install clang ;;
    esac
    if ! have cargo; then
        log "    installing rust toolchain (rustup)"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
        export PATH="$HOME/.cargo/bin:$PATH"
    fi
    cargo install tree-sitter-cli --root "$PREFIX"
}

if skip tree-sitter; then
    log ">>> tree-sitter CLI (skipped)"
elif ts_ok; then
    log ">>> tree-sitter CLI ($(tree-sitter --version | awk '{print $2}')) — ok"
else
    log ">>> tree-sitter CLI (need >= ${TREE_SITTER_MIN})"
    if [ "$PKG" = brew ]; then
        pkg_install tree-sitter-cli
    else
        # Map uname -m to upstream's release asset naming.
        case "$ARCH" in
            x86_64)  TS_ASSET=linux-x64 ;;
            aarch64) TS_ASSET=linux-arm64 ;;
            armv7l)  TS_ASSET=linux-arm ;;
            i686)    TS_ASSET=linux-x86 ;;
            *)       TS_ASSET="" ;;
        esac

        GLIBC="$(ldd --version 2>/dev/null | head -1 | awk '{print $NF}')"
        PREBUILT_OK=false
        if [ -n "$TS_ASSET" ] && [ -n "$GLIBC" ] && version_ge "$GLIBC" 2.39; then
            PREBUILT_OK=true
        fi

        if [ "$PREBUILT_OK" = true ]; then
            log "    downloading prebuilt tree-sitter (${TS_ASSET}, glibc ${GLIBC})"
            TS_TMP="$(mktemp -d)"
            curl -fsSL -o "$TS_TMP/ts.gz" \
                "https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-${TS_ASSET}.gz"
            gunzip -f "$TS_TMP/ts.gz"
            chmod +x "$TS_TMP/ts"
            # Verify it actually runs on this host before replacing anything.
            if "$TS_TMP/ts" --version > /dev/null 2>&1; then
                mv "$TS_TMP/ts" "$LOCAL_BIN/tree-sitter"
            else
                rm -rf "$TS_TMP"
                install_tree_sitter_from_source
            fi
            rm -rf "$TS_TMP"
        else
            install_tree_sitter_from_source
        fi
    fi
    ts_ok || note_missing "tree-sitter CLI >= ${TREE_SITTER_MIN} (nvim-treesitter cannot install parsers)"
fi

# -----------------------------------------------------------------------------
# 3. Search tools — telescope's find_files/live_grep
# -----------------------------------------------------------------------------
log ">>> Search tools (ripgrep, fd)"
if ! have rg || ! have fd; then
    case "$PKG" in
        brew)   pkg_install ripgrep fd ;;
        apt)    pkg_install ripgrep fd-find
                # Debian/Ubuntu ship the binary as `fdfind` to avoid a name clash.
                if ! have fd && have fdfind; then ln -sf "$(command -v fdfind)" "$LOCAL_BIN/fd"; fi ;;
        dnf)    pkg_install ripgrep fd-find ;;
        pacman) pkg_install ripgrep fd ;;
    esac
fi
have rg || note_missing "ripgrep (telescope live_grep)"
have fd || note_missing "fd (telescope find_files)"

# -----------------------------------------------------------------------------
# 4. Language runtimes that mason installs *onto*
#
#    mason runs unprivileged and only installs leaf packages; the runtimes have
#    to exist already. ensure_installed = lua_ls, rust_analyzer, pyright, ruff:
#      pyright  -> node
#      ruff     -> a python venv (stock Debian python3 has neither pip nor venv)
#      lua_ls   -> prebuilt archive (unzip, handled above)
#      rust_analyzer -> prebuilt archive
# -----------------------------------------------------------------------------
log ">>> Language runtimes (python, node)"
case "$PKG" in
    brew)   pkg_install python3 ;;
    apt)    pkg_install python3 python3-pip python3-venv ;;
    dnf)    pkg_install python3 python3-pip ;;
    pacman) pkg_install python python-pip ;;
esac

# node: prefer an existing nvm/system install; only install one if absent.
# augment.vim also requires node, so this is not mason-only.
if ! have node; then
    if [ -s "$HOME/.nvm/nvm.sh" ]; then
        # shellcheck disable=SC1091
        . "$HOME/.nvm/nvm.sh"
    fi
fi
if ! have node; then
    log "    node missing — installing via ubuntu-install/node-install.sh"
    if [ "$PKG" = brew ]; then
        pkg_install node
    elif [ -f "$DOTFILES_DIR/ubuntu-install/node-install.sh" ]; then
        bash "$DOTFILES_DIR/ubuntu-install/node-install.sh"
        # shellcheck disable=SC1091
        [ -s "$HOME/.nvm/nvm.sh" ] && . "$HOME/.nvm/nvm.sh"
    fi
fi
have node || note_missing "node (mason pyright, augment.vim)"

# -----------------------------------------------------------------------------
# 5. JDK — nvim-jdtls
# -----------------------------------------------------------------------------
if skip java; then
    log ">>> JDK (skipped)"
elif have javac; then
    log ">>> JDK — ok"
else
    log ">>> JDK (nvim-jdtls)"
    case "$PKG" in
        brew)   pkg_install openjdk ;;
        apt)    pkg_install default-jdk ;;
        dnf)    pkg_install java-latest-openjdk-devel ;;
        pacman) pkg_install jdk-openjdk ;;
    esac
    have javac || note_missing "javac (nvim-jdtls)"
fi

# -----------------------------------------------------------------------------
# 6. ImageMagick — image.nvim is configured with processor = "magick_cli",
#    which shells out to the ImageMagick 7 `magick` binary.
#
#    Debian 12 / Ubuntu <= 24.04 still ship ImageMagick 6, which has no `magick`
#    entrypoint — only the v6 `convert`. The v6 CLI accepts the same invocations
#    image.nvim makes, so a shim keeps the plugin working on those releases
#    rather than leaving it silently broken.
# -----------------------------------------------------------------------------
if skip imagemagick; then
    log ">>> ImageMagick (skipped)"
elif have magick; then
    log ">>> ImageMagick — ok"
else
    log ">>> ImageMagick (image.nvim)"
    case "$PKG" in
        brew)   pkg_install imagemagick ;;
        apt)    pkg_install imagemagick ;;
        dnf)    pkg_install ImageMagick ;;
        pacman) pkg_install imagemagick ;;
    esac
    if ! have magick && have convert; then
        log "    ImageMagick 6 detected — installing a \`magick\` shim over \`convert\`"
        cat > "$LOCAL_BIN/magick" <<'SHIM'
#!/bin/sh
# ImageMagick 6 compatibility shim for image.nvim (processor = "magick_cli"),
# which invokes the v7-only `magick` entrypoint. Installed by nvim/nvim-deps.sh.
exec convert "$@"
SHIM
        chmod +x "$LOCAL_BIN/magick"
    fi
    have magick || note_missing "magick (image.nvim)"
fi

# -----------------------------------------------------------------------------
# 7. Clipboard + URL opener
#    Clipboard: nvim's "+ register, and obsidian.nvim's :Obsidian paste_img.
#    xdg-open:  vim.ui.open, used by `gx` and vim-rhubarb's :GBrowse.
# -----------------------------------------------------------------------------
if [ "$PKG" = brew ]; then
    log ">>> Clipboard / opener — ok (pbcopy, open)"
else
    log ">>> Clipboard / URL opener"
    if [ -n "${WAYLAND_DISPLAY:-}" ]; then
        have wl-copy || pkg_install wl-clipboard
    else
        have xclip || case "$PKG" in
            dnf) pkg_install xclip ;;
            *)   pkg_install xclip ;;
        esac
    fi
    have xdg-open || case "$PKG" in
        apt)    pkg_install xdg-utils ;;
        dnf)    pkg_install xdg-utils ;;
        pacman) pkg_install xdg-utils ;;
    esac
fi

# -----------------------------------------------------------------------------
# 8. himalaya CLI — himalaya.nvim is a frontend over it, and ships no binary.
# -----------------------------------------------------------------------------
if skip himalaya; then
    log ">>> himalaya (skipped)"
elif have himalaya; then
    log ">>> himalaya — ok"
else
    log ">>> himalaya CLI (himalaya.nvim)"
    case "$OS-$ARCH" in
        Darwin-arm64)  HIM_ASSET=aarch64-darwin ;;
        Darwin-x86_64) HIM_ASSET=x86_64-darwin ;;
        Linux-x86_64)  HIM_ASSET=x86_64-linux ;;
        Linux-aarch64) HIM_ASSET=aarch64-linux ;;
        *)             HIM_ASSET="" ;;
    esac
    if [ -n "$HIM_ASSET" ]; then
        HIM_TMP="$(mktemp -d)"
        if curl -fsSL "https://github.com/pimalaya/himalaya/releases/latest/download/himalaya.${HIM_ASSET}.tgz" \
                | tar xz -C "$HIM_TMP" 2>/dev/null; then
            # The tarball layout has moved between releases; find the binary.
            HIM_BIN="$(find "$HIM_TMP" -type f -name himalaya -perm -u+x | head -1)"
            [ -n "$HIM_BIN" ] && mv "$HIM_BIN" "$LOCAL_BIN/himalaya"
        fi
        rm -rf "$HIM_TMP"
    fi
    have himalaya || note_missing "himalaya (himalaya.nvim — <leader>oh)"
fi

# -----------------------------------------------------------------------------
# 9. TeX — vimtex's compiler is latexmk. Opt-in: a usable TeX install is
#    multiple GB, which is not something to drop on every VM by default.
# -----------------------------------------------------------------------------
if [ "$WITH_TEX" = true ]; then
    log ">>> TeX toolchain (vimtex)"
    case "$PKG" in
        brew)   brew install --cask mactex-no-gui ;;
        apt)    pkg_install texlive-latex-recommended texlive-latex-extra latexmk biber ;;
        dnf)    pkg_install texlive-scheme-medium latexmk biber ;;
        pacman) pkg_install texlive-basic texlive-latexextra texlive-binextra biber ;;
    esac
    have latexmk || note_missing "latexmk (vimtex)"
else
    log ">>> TeX toolchain — skipped (pass --tex to install; vimtex needs latexmk)"
fi

# -----------------------------------------------------------------------------
# 10. Bootstrap the config headlessly
# -----------------------------------------------------------------------------
if [ "$BOOTSTRAP" = false ]; then
    log ">>> Bootstrap skipped (--no-bootstrap)"
elif ! have nvim; then
    note_missing "nvim itself (build it with nvim/nv-build.sh, or brew install neovim)"
    log ">>> Bootstrap skipped — nvim not on PATH"
else
    log ">>> Bootstrap: lazy sync"
    # lazy's task log is verbose; keep only real failures and the summary lines.
    nvim --headless "+Lazy! sync" +qa 2>&1 \
        | grep -E '^(E[0-9]+:)|error|Error' | grep -vi "cannot query terminal size" || true

    log ">>> Bootstrap: treesitter parsers"
    # Read the parser list straight out of the config so the two can't drift.
    PARSERS="$(sed -n "/^ts.install({/,/})/p" "$DOTFILES_DIR/nvim/after/plugin/treesitter.lua" \
        | grep -o "'[a-z_]*'" | tr -d "'" | paste -sd, -)"
    if [ -n "$PARSERS" ]; then
        LUA_LIST="$(echo "$PARSERS" | sed "s/[^,]*/'&'/g")"
        nvim --headless \
            -c "lua require('nvim-treesitter').install({${LUA_LIST}}):wait(900000)" \
            -c 'qa' 2>&1 | grep -E '^(E[0-9]+:|.*\[nvim-treesitter.*(rror|ailed))' || true
    fi

    log ">>> Bootstrap: mason servers"
    nvim --headless \
        -c 'lua vim.cmd("MasonInstall lua-language-server rust-analyzer pyright ruff")' \
        -c 'qa' 2>&1 | grep -E '^(E[0-9]+:|.*failed to install)' || true
fi

# -----------------------------------------------------------------------------
# 11. Verification
# -----------------------------------------------------------------------------
echo ""
echo "============================================"
echo "  Verification"
echo "============================================"
check() {
    if have "$2"; then echo "  ✓ $1"; else echo "  ✗ $1: NOT FOUND"; fi
}
check "neovim"            nvim
check "tree-sitter CLI"   tree-sitter
check "ripgrep"           rg
check "fd"                fd
check "git"               git
check "cc"                cc
check "node"              node
check "python3"           python3
check "javac"             javac
check "magick"            magick
check "himalaya"          himalaya
[ "$WITH_TEX" = true ] && check "latexmk" latexmk

PARSER_DIR="$HOME/.local/share/nvim/site/parser"
if [ -d "$PARSER_DIR" ]; then
    echo "  ✓ treesitter parsers: $(find "$PARSER_DIR" -name '*.so' | wc -l | tr -d ' ') installed"
else
    echo "  ✗ treesitter parsers: none installed"
fi

if [ ${#MISSING[@]} -gt 0 ]; then
    echo ""
    echo "  Unresolved:"
    for m in "${MISSING[@]}"; do echo "    - $m"; done
fi

echo ""
echo "============================================"
echo "  Done (${SECONDS}s). Run :checkhealth in nvim."
echo "============================================"
