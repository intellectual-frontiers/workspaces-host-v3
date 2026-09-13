{ pkgs }:

pkgs.stdenvNoCC.mkDerivation {
  pname = "semtag";
  version = "1.0.0";
  src = ./.;
  dontUnpack = true;

  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    runHook preInstall
    install -Dm755 ${./semtag} $out/bin/semtag
    wrapProgram $out/bin/semtag \
      --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.git pkgs.gnused pkgs.coreutils ]}
    runHook postInstall
  '';

  meta = {
    description = "Compute and optionally apply the next semantic version git tag";
    mainProgram = "semtag";
  };
}
