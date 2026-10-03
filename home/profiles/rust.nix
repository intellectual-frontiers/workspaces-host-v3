{ pkgs, config, ... }:

let
  # Named once so both `home.packages` and `RUST_SRC_PATH` below refer
  # to the exact same build - two separate
  # `pkgs.rust-bin.stable.latest.minimal.override { ... }` calls
  # wouldn't necessarily evaluate to the same derivation.
  #
  # `.minimal`, not `.default`: rust-overlay's `default` profile (its
  # name for rustup's own "default" profile) bundles `rust-docs` - the
  # full rendered HTML standard-library documentation, confirmed
  # directly to add real weight to the built image (the published image
  # has no browser to read it in anyway) - for no benefit over
  # rust-analyzer's own hover docs, which read source, not this bundle.
  # `.minimal.override` starts from rustc+cargo+rust-std alone and adds
  # back only the components this persona actually needs.
  rustToolchain = pkgs.rust-bin.stable.latest.minimal.override {
    extensions = [ "clippy" "rustfmt" "rust-src" "rust-analyzer" ];
  };
in
{
  # Rust toolchain (spec 029, amended): this flake's pinned nixpkgs
  # revision ships rustc 1.86.0, which clears the >=1.85 floor edition
  # 2024 needs in the abstract - but `www.intellectualfrontiers.com`'s
  # own, real `Cargo.lock` pins `oxrdf`/`oxttl` versions that need
  # rustc 1.87, found by actually running `cargo test --locked` against
  # that repo, not assumed from its own declared `rust-version` alone.
  # nixpkgs' pinned revision genuinely isn't new enough, so - per this
  # persona's own design - `rust-overlay` (flake.nix's `rust-overlay`
  # input, locked by `flake.lock` like every other input here) supplies
  # a current `stable` release instead of an imperative installer
  # (rustup - Constitution Principle I). `.default` is rust-overlay's
  # own bundled profile (rustc, cargo, clippy, rustfmt, the standard
  # library) in one derivation; `.override` adds the `rust-src`
  # component rust-analyzer needs and the matching `rust-analyzer`
  # component itself, so it's never out of sync with the rustc it's
  # analyzing the way pulling nixpkgs' own, separately-versioned
  # `rust-analyzer` package would risk.
  home.packages = [
    rustToolchain
  ] ++ [
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
    # own source, not just its compiled rlib) reads this - pointed at
    # the `rust-src` component on `rustToolchain` itself (above), the
    # exact same version as the rustc it's analyzing, not nixpkgs' own,
    # separately-versioned rust-src.
    RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
  };
}
