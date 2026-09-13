{ pkgs }:

let
  version = "3.63.0";

  # surveilr's GitHub releases (surveilr/packages) only publish x86_64
  # binaries: a tar.gz for Linux (glibc) and a zip for Darwin. No aarch64
  # asset of either kind exists yet, so `assets` below only has entries
  # for the two systems that actually have something to fetch - see
  # pkgs/default.nix for how this package is made present only on those
  # systems rather than failing evaluation elsewhere.
  assets = {
    x86_64-linux = {
      url = "https://github.com/surveilr/packages/releases/download/${version}/surveilr_${version}_x86_64-unknown-linux-gnu.tar.gz";
      hash = "sha256-MDySyWNfF+g1aRb576cJxlZLQyUw2l4PUWEToItfnlw=";
    };
    x86_64-darwin = {
      url = "https://github.com/surveilr/packages/releases/download/${version}/surveilr_${version}_x86_64-apple-darwin.zip";
      hash = "sha256-MlEjpJ01GZFhWO+oTAhCvmCfeIWuldIBr2kCqWO84bU=";
    };
  };

  asset = assets.${pkgs.stdenv.hostPlatform.system} or (throw
    "surveilr: no published release asset for ${pkgs.stdenv.hostPlatform.system}");

  src = pkgs.fetchurl { inherit (asset) url hash; };
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "surveilr";
  inherit version src;

  # Both the tar.gz and the zip contain a single flat `surveilr` binary
  # with no enclosing directory, which stdenv's generic unpackPhase
  # rejects ("unpacker appears to have produced no directories") - so
  # unpacking is done by hand in installPhase instead. `unzip` is needed
  # only for the Darwin asset, but is harmless to include unconditionally.
  dontUnpack = true;
  nativeBuildInputs = [ pkgs.unzip ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    case "${src}" in
      *.zip) unzip -p "${src}" surveilr > $out/bin/surveilr ;;
      *) tar -xOzf "${src}" surveilr > $out/bin/surveilr ;;
    esac
    chmod 755 $out/bin/surveilr
    runHook postInstall
  '';

  meta = {
    description = "Resource Surveillance and Integration Engine - captures machine/file/database state into SQLite for SOC2 and other compliance evidence (surveilr/packages release binary)";
    mainProgram = "surveilr";
    platforms = builtins.attrNames assets;
  };
}
