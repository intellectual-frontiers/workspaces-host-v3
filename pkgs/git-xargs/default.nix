{ pkgs }:

let
  version = "0.1.16";

  # gruntwork-io/git-xargs publishes a plain (unarchived) static binary
  # per platform on its GitHub releases - all four of this flake's
  # supported systems have one, unlike surveilr (compliance/observability
  # tooling), which doesn't.
  assets = {
    x86_64-linux = {
      name = "git-xargs_linux_amd64";
      hash = "sha256-DfTjeFMkm/e6D/NQZt7ci+sCoGYJiEFKB1J/GmutqYQ=";
    };
    aarch64-linux = {
      name = "git-xargs_linux_arm64";
      hash = "sha256-8alpG4qO6rtsoRkd+hZGCI+LEM8bg3GCu/pmChuoFlo=";
    };
    x86_64-darwin = {
      name = "git-xargs_darwin_amd64";
      hash = "sha256-cmQ05k5cU7bzsz3jhpcwJxLWMePmyEGjxdbdXR25njQ=";
    };
    aarch64-darwin = {
      name = "git-xargs_darwin_arm64";
      hash = "sha256-G38eX6HVoNAQoEfghFP2Z0PFUAs7QiN71avMvWwd0R4=";
    };
  }.${pkgs.stdenv.hostPlatform.system} or (throw
    "git-xargs: no published release asset for ${pkgs.stdenv.hostPlatform.system}");

  src = pkgs.fetchurl {
    url = "https://github.com/gruntwork-io/git-xargs/releases/download/v${version}/${assets.name}";
    hash = assets.hash;
  };
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "git-xargs";
  inherit version src;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 ${src} $out/bin/git-xargs
    runHook postInstall
  '';

  meta = {
    description = "Run a command (or a Go callback) against many GitHub repos at once, opening a PR with the results in each";
    mainProgram = "git-xargs";
  };
}
