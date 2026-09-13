{ pkgs }:

let
  version = "1.51.0";

  # backlog.md publishes to npm as a thin Node wrapper (cli.js +
  # resolveBinary.cjs) plus a platform-specific optionalDependency package
  # holding the actual compiled binary - so packaging it is "fetch two
  # tarballs and wire them together", not a from-source Bun/Node build.
  platformPackage = {
    x86_64-linux = {
      name = "backlog.md-linux-x64";
      hash = "sha512-+Nz/Rsmh3HsNEBA2TrDtrPVg+WDnhOQsPNmj39LGXfeGsDc4W1GJvNm29jTk9zGBgbE5/4NVp2UfHhNlgOUNIQ==";
    };
    aarch64-linux = {
      name = "backlog.md-linux-arm64";
      hash = "sha512-+Area163fPlOhSpH2DvXJ1/C22HIVAVGYVAcieOZzhyCczEn/ToyvLg8/j5qxXx6JWBBun/Di+KY5o3TcgAQDg==";
    };
    x86_64-darwin = {
      name = "backlog.md-darwin-x64";
      hash = "sha512-PO4hiVFCAHlKTE0DgdnhJN49N59mmpcrPvSf/vmnnmQXC6TDt6ScEjuOv7gjflC0xgTdBLdFcMthGbeAxb9JZg==";
    };
    aarch64-darwin = {
      name = "backlog.md-darwin-arm64";
      hash = "sha512-gM5rnBo/ZKfGW1nmbd10U9q2hZfOr8U4Q0Nq5naCQbDxoUkXzV+h84wcMybicl/7w2W9r9bjJkasbdqSPplmBw==";
    };
  }.${pkgs.stdenv.hostPlatform.system} or (throw
    "backlog-md: no published binary for ${pkgs.stdenv.hostPlatform.system}");

  main = pkgs.fetchurl {
    url = "https://registry.npmjs.org/backlog.md/-/backlog.md-${version}.tgz";
    hash = "sha512-tVNl1XrLThAvnuvP3XgUlofCWsNKP6OWGiWRcIdnyxeL/ovWq/RycWTJDpedUqISoFiPlkUENB2AbH7ag04q7g==";
  };

  binaryTarball = pkgs.fetchurl {
    url = "https://registry.npmjs.org/${platformPackage.name}/-/${platformPackage.name}-${version}.tgz";
    hash = platformPackage.hash;
  };
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "backlog-md";
  inherit version;
  dontUnpack = true;

  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    runHook preInstall

    mainDir=$out/lib/node_modules/backlog.md
    binDir=$out/lib/node_modules/${platformPackage.name}
    mkdir -p "$mainDir" "$binDir"

    tar -xzf ${main} -C "$mainDir" --strip-components=1
    tar -xzf ${binaryTarball} -C "$binDir" --strip-components=1
    chmod +x "$binDir"/backlog

    makeWrapper ${pkgs.nodejs}/bin/node $out/bin/backlog \
      --add-flags "$mainDir/cli.js"

    runHook postInstall
  '';

  meta = {
    description = "Backlog.md - a markdown-native task/kanban backlog manager for AI coding agents";
    mainProgram = "backlog";
  };
}
