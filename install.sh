#!/bin/sh
# install.sh: one-step installer for workspaces-host-v3. Safe to re-run -
# every step is idempotent (skips whatever's already done, and re-runs
# just pull + rebuild + reactivate if you've already installed once).
#
# Usage:
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/intellectual-frontiers/workspaces-host-v3/main/install.sh)"
#
# Deliberately NOT `curl ... | sh`: that form hands this script's own
# stdin to the shell running it, so anything downstream that ever needs
# to read real terminal input (a sudo password prompt) can't. `sh -c
# "$(curl ...)"` downloads the whole script into an argument first, so
# your terminal's actual stdin is untouched the entire time.
set -eu

log() { echo "workspaces-host-v3 install: $*" >&2; }
die() {
    echo "workspaces-host-v3 install: error: $*" >&2
    exit 1
}

: "${WORKSPACES_HOST_REPO:=$HOME/.workspaces-host-v3}"
: "${WORKSPACES_HOST_PROFILE:=current}"
# Some shells/environments don't export $USER even though `whoami` works
# - the `current` profile needs it for your real identity.
: "${USER:=$(whoami)}"
export USER WORKSPACES_HOST_REPO WORKSPACES_HOST_PROFILE

as_root() {
    if [ "$(id -u)" = "0" ]; then
        "$@"
    else
        sudo "$@"
    fi
}

# --- 1. Prerequisites (curl, git, xz) - auto-sensed per distro family --
if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
else
    ID=""
    ID_LIKE=""
fi
family=" ${ID:-} ${ID_LIKE:-} "

install_prereqs_linux() {
    if command -v curl >/dev/null 2>&1 && command -v git >/dev/null 2>&1 && command -v xz >/dev/null 2>&1; then
        log "curl, git, and xz already present"
        return
    fi
    case "$family" in
    *" debian "* | *" ubuntu "*)
        log "installing curl/git/xz via apt (Debian/Ubuntu family)"
        as_root apt-get update
        as_root apt-get install -y curl git xz-utils
        ;;
    *" rhel "* | *" fedora "* | *" centos "*)
        log "installing curl/git/xz via dnf (RHEL/Fedora family)"
        as_root dnf install -y curl git xz
        ;;
    *" arch "*)
        log "installing curl/git/xz via pacman (Arch family)"
        as_root pacman -Sy --noconfirm curl git xz
        ;;
    *)
        die "unrecognized Linux distro (ID=${ID:-?} ID_LIKE=${ID_LIKE:-?}) - install curl, git, and xz yourself, then re-run this script"
        ;;
    esac
}

# A fresh Debian/WSL image commonly ships LANG=en_US.UTF-8 as the OS
# default without ever generating that locale, which prints a
# "setlocale: cannot change locale" warning on every single shell -
# before this script, before Nix, before anything of ours runs. C.UTF-8
# is a special locale glibc always has built in (no locale-gen needed),
# so switching the OS default to it fixes this permanently. Separate
# from install_prereqs_linux and always run (not skipped by its
# curl/git/xz-already-present early return) since a re-run should still
# fix this if it was never fixed before.
fix_locale_linux() {
    case "$family" in
    *" debian "* | *" ubuntu "*)
        command -v update-locale >/dev/null 2>&1 || return 0
        log "setting the default locale to C.UTF-8 (avoids the 'setlocale: cannot change locale' warning a fresh Debian/WSL image prints on every shell)"
        as_root update-locale LANG=C.UTF-8 LC_ALL=C.UTF-8
        ;;
    esac
}

os=$(uname -s)
case "$os" in
Linux)
    install_prereqs_linux
    fix_locale_linux
    ;;
Darwin)
    command -v curl >/dev/null 2>&1 || die "curl not found - install the Xcode Command Line Tools (xcode-select --install) and re-run"
    command -v git >/dev/null 2>&1 || die "git not found - install the Xcode Command Line Tools (xcode-select --install) and re-run"
    command -v xz >/dev/null 2>&1 || die "xz not found - install it (e.g. 'brew install xz') and re-run"
    log "curl, git, and xz already present (macOS)"
    ;;
*)
    die "unsupported OS: $os - this installer covers Linux and macOS (on Windows, run this from inside WSL)"
    ;;
esac

# --- 2. Install Nix (single-user, idempotent) --------------------------
if command -v nix >/dev/null 2>&1; then
    log "Nix already installed"
else
    log "installing Nix (single-user - no systemd/daemon required)"
    nix_installer=$(mktemp)
    trap 'rm -f "$nix_installer"' EXIT
    curl -fsSL https://nixos.org/nix/install -o "$nix_installer"
    sh "$nix_installer" --no-daemon </dev/null
    rm -f "$nix_installer"
    trap - EXIT
fi

# Make `nix` usable in *this* script's shell right away, without
# requiring a new terminal window first.
for candidate in "$HOME/.nix-profile/etc/profile.d/nix.sh" "/etc/profile.d/nix.sh"; do
    if [ -f "$candidate" ]; then
        # shellcheck disable=SC1090
        . "$candidate"
        break
    fi
done
command -v nix >/dev/null 2>&1 || die "nix was installed but isn't on PATH yet - open a new terminal and re-run this script"

# --- 3. Enable flakes (idempotent - no duplicate lines on a re-run) ---
mkdir -p "$HOME/.config/nix"
if ! grep -q "experimental-features.*flakes" "$HOME/.config/nix/nix.conf" 2>/dev/null; then
    log "enabling nix-command and flakes"
    echo "experimental-features = nix-command flakes" >>"$HOME/.config/nix/nix.conf"
fi

# --- 4. Clone (or update, if already cloned) this repo -----------------
if [ -d "$WORKSPACES_HOST_REPO/.git" ]; then
    log "updating existing clone at $WORKSPACES_HOST_REPO"
    git -C "$WORKSPACES_HOST_REPO" pull --ff-only
elif [ -e "$WORKSPACES_HOST_REPO" ]; then
    die "$WORKSPACES_HOST_REPO exists but isn't a git clone - move it aside, or set WORKSPACES_HOST_REPO to a different path and re-run"
else
    log "cloning to $WORKSPACES_HOST_REPO"
    git clone https://github.com/intellectual-frontiers/workspaces-host-v3.git "$WORKSPACES_HOST_REPO"
fi

# --- 5. Create the credentials file, if it doesn't exist yet -----------
credentials_file="${XDG_CONFIG_HOME:-$HOME/.config}/workspaces-host/credentials"
if [ ! -f "$credentials_file" ]; then
    log "creating $credentials_file from the template"
    mkdir -p "$(dirname "$credentials_file")"
    cp "$WORKSPACES_HOST_REPO/credentials.example" "$credentials_file"
    chmod 600 "$credentials_file"
fi

# --- 6. Build and activate ----------------------------------------------
cd "$WORKSPACES_HOST_REPO"
log "building $WORKSPACES_HOST_PROFILE (downloads everything needed - can take a few minutes the first time)"
nix build ".#homeConfigurations.${WORKSPACES_HOST_PROFILE}.activationPackage" --impure
log "activating"
# A brand-new account already has its own ~/.bashrc/~/.profile - ordinary
# files, not symlinks, so home-manager safely refuses to overwrite them
# by default. HOME_MANAGER_BACKUP_EXT makes it move them aside first
# instead of failing.
export HOME_MANAGER_BACKUP_EXT="pre-workspaces-host-backup"
./result/activate

# --- 7. Make this repo's own bash the actual login shell (best-effort) -
bash_path="$HOME/.nix-profile/bin/bash"
if [ -x "$bash_path" ]; then
    current_shell=$(getent passwd "$USER" 2>/dev/null | cut -d: -f7)
    if [ "$current_shell" != "$bash_path" ]; then
        log "setting this repo's pinned bash as your login shell"
        if grep -qxF "$bash_path" /etc/shells 2>/dev/null || as_root sh -c "echo '$bash_path' >> /etc/shells" 2>/dev/null; then
            if as_root chsh -s "$bash_path" "$USER" 2>/dev/null; then
                log "done - open a new terminal window to see it take effect"
            else
                log "couldn't change your login shell automatically - run 'chsh -s $bash_path' yourself if you want the exact same bash version as everyone else on this setup"
            fi
        else
            log "couldn't register $bash_path in /etc/shells - run 'chsh -s $bash_path' yourself if you want the exact same bash version as everyone else on this setup"
        fi
    fi
fi

log "done - open a new shell, then:"
log "  1. edit $credentials_file (your name/email) and run 'workspaces-host-update' to apply it"
log "  2. run 'doctor' to verify everything"
