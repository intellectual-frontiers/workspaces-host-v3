{ pkgs, config, ... }:

{
  # Rust toolchain (addendum to spec 029): nixpkgs' own pinned rustc/
  # cargo/clippy/rustfmt already clear the >=1.85 floor edition 2024
  # needs - this flake's pinned nixos-25.05 revision ships 1.86.0,
  # checked directly (`nix eval`) rather than assumed - so this persona
  # uses nixpkgs' own packages instead of an imperative installer
  # (rustup, which manages its own toolchains outside Nix entirely -
  # Constitution Principle I) or a second flake input (rust-overlay/
  # fenix) pinning a toolchain nixpkgs already provides new enough.
  # `rust-analyzer` comes from the same pinned nixpkgs revision, so it
  # never drifts out of sync with the rustc it's analyzing.
  home.packages = (with pkgs; [
    rustc
    cargo
    clippy
    rustfmt
    rust-analyzer
  ]) ++ [
    # The native build toolchain a `reqwest`+rustls dependency tree
    # actually needs: `aws-lc-sys` and `ring` both compile C/assembly at
    # `cargo build` time, not merely link a prebuilt library - confirmed
    # directly by building that exact crate graph end to end, the
    # hardest native dependency an Intellectual Frontiers repo's own
    # Cargo.toml pulls in. `stdenv.cc` is this platform's own default
    # compiler wrapper (GCC on Linux, Clang on Darwin) rather than a
    # hardcoded `gcc`, so this persona doesn't force a from-source GCC
    # build on a platform nixpkgs doesn't carry cached GCC binaries for
    # - and it already bundles its own linker (`ld`/`ar`/`as`/etc., from
    # GNU binutils on Linux) in the same package, so nothing extra is
    # needed for that half of "a C compiler and linker".
    pkgs.stdenv.cc
    pkgs.cmake
    pkgs.pkg-config
    pkgs.perl
    # gnumake is already unconditional in home/tools.nix (the base
    # profile), so it isn't repeated here.
  ];

  home.sessionVariables = {
    # A writable Cargo home under $HOME, not the Nix store: the
    # registry index and git checkout caches `cargo add`/`cargo build`
    # write on every run have to land somewhere mutable. `$HOME/.cargo`
    # is cargo's own documented default location, made explicit here so
    # it's never accidentally inherited from a stray environment
    # variable in whatever shell this profile ends up running under.
    CARGO_HOME = "${config.home.homeDirectory}/.cargo";
    # rust-analyzer (and anything else wanting the standard library's
    # own source, not just its compiled rlib) reads this - nixpkgs' own
    # `rustPlatform.rustLibSrc` is exactly the pinned rust-src nixpkgs
    # already carries for this same rustc revision, not a second
    # download or a `rustup component add rust-src` step.
    RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
  };
}
