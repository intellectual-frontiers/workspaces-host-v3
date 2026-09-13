{ pkgs }:

pkgs.stdenvNoCC.mkDerivation {
  pname = "mgit";
  version = "1.0.0";
  src = ./.;
  dontUnpack = true;

  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    runHook preInstall
    install -Dm755 ${./mgit} $out/bin/mgit
    wrapProgram $out/bin/mgit \
      --prefix PATH : ${pkgs.lib.makeBinPath [
        pkgs.git
        pkgs.jq
        pkgs.findutils
        pkgs.coreutils
        pkgs.gnugrep
        pkgs.gnused
      ]}
    runHook postInstall
  '';

  meta = {
    description = "Clone-or-pull git repos into ~/workspaces by a governed <host>/<org>/<repo> convention, with VS Code multi-root *.mgit.code-workspace symlinking and a status report";
    mainProgram = "mgit";
  };
}
