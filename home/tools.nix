{ pkgs, ... }:

let
  # mgit, doctor, and workspaces-host-update (pkgs/default.nix) - built as
  # flake packages, but only actually land on PATH once they're also
  # listed in home.packages like every other tool here.
  ported = import ../pkgs { inherit pkgs; };
in
{
  # Everyday CLI tools pinned by the flake's own nixpkgs input (spec 001
  # FR-007). Kept deliberately small for v3's core: `ripgrep`/`fd` back
  # fzf's file/dir widgets (home/shell.nix), `jq`/`findutils` back `mgit`
  # (pkgs/mgit), `eza`/`bat` are the aliased `ls`/`cat` replacements
  # (home/shell.nix), and `blesh` is bash's syntax-highlighting/
  # autosuggestion engine sourced directly by store path there - listed
  # here too so its own helper commands are on PATH for manual use.
  home.packages = (builtins.attrValues ported) ++ (with pkgs; [
    ripgrep
    fd
    jq
    bat
    eza
    blesh
  ]);
}
