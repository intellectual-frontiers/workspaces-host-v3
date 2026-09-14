## Windows, via WSL

Most people reading this are on Windows. WSL runs a real Linux system next to your normal Windows apps. Everything below happens inside that Linux system, except step 1.

### Steps

1. Open PowerShell as Administrator. Run:

   ```
   wsl --install -d Debian
   ```

   This may ask you to restart your computer.

2. Open "Debian" from the Start menu. The first time it opens, pick a Linux username and password (different from your Windows login).

3. From inside that Debian window, run this one line:

   ```
   $ cd && sudo apt-get update && sudo apt-get install -y curl git && sh -c "$(curl -fsSL https://raw.githubusercontent.com/intellectual-frontiers/workspaces-host-v3/main/install.sh)"
   ```

   `sudo` asks for the password from step 2. That's the only password prompt in the whole process. It takes a few minutes the first time; safe to run again later.

4. Fill in your credentials and apply them:

   ```
   $ nano ~/.config/workspaces-host/credentials
   $ workspaces-host-update
   ```

5. Close this window and open a new one. Look for the new prompt and autosuggestions as you type. That's your confirmation it worked.

> [!TIP]
> New window looks the same as the old one? Run `doctor`. It names the exact problem and the exact fix. See [Verify it worked](#getting-started/first-day).

### Using VS Code with WSL

1. Install VS Code on **Windows** (not inside Debian): [code.visualstudio.com](https://code.visualstudio.com/).
2. Install the **"WSL" extension** in that Windows VS Code (published by Microsoft).
3. From your Debian window, in any project folder, run `code .` The first time, this installs a small VS Code Server inside WSL and opens a normal VS Code window running entirely inside Linux.

## Linux

Open a regular terminal. Most VM/cloud images already have `curl`/`git`/`xz`; a bare-bones one won't.

```
$ sudo apt-get install -y curl git xz-utils   # Debian/Ubuntu
$ sudo dnf install -y curl git xz             # RHEL/Fedora/CentOS
$ sudo pacman -Sy --noconfirm curl git xz     # Arch
```

Then run:

```
$ sh -c "$(curl -fsSL https://raw.githubusercontent.com/intellectual-frontiers/workspaces-host-v3/main/install.sh)"
```

`install.sh` auto-detects which of those three families you're on for anything else it needs. Want to build or run this repo's container images too?

```
$ sudo apt install -y docker.io   # Debian/Ubuntu; see docs.docker.com for other distros
```

## macOS

`curl`, `git`, and `xz` are already there. Apple Silicon or Intel, run the same one-liner:

```
$ sh -c "$(curl -fsSL https://raw.githubusercontent.com/intellectual-frontiers/workspaces-host-v3/main/install.sh)"
```

Container sandboxing (the network-restricted image) doesn't run on macOS. Everything else does.

## Manual, step by step

If you'd rather run each step yourself instead of the one-liner:

```
$ sudo apt update && sudo apt install -y curl git xz-utils   # skip on macOS
$ sh <(curl -L https://nixos.org/nix/install) --no-daemon
$ mkdir -p ~/.config/nix
$ echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
$ git clone https://github.com/intellectual-frontiers/workspaces-host-v3.git ~/.workspaces-host-v3
$ cd ~/.workspaces-host-v3
$ nix build ".#homeConfigurations.current.activationPackage" --impure
$ export HOME_MANAGER_BACKUP_EXT=pre-workspaces-host-backup
$ ./result/activate
```

`install.sh` in the repository is the real source of truth for these steps.

## What's next

Head to [Verify it worked & your first day](#getting-started/first-day) to confirm it's actually running, then [Day to Day](#day-to-day/personas) for everything you'll touch after that.
