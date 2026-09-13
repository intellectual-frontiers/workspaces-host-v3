{ pkgs }:

pkgs.stdenvNoCC.mkDerivation {
  pname = "ws-repos";
  version = "1.0.0";
  src = ./.;
  dontUnpack = true;

  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    runHook preInstall
    install -Dm755 ${./ws-repos} $out/bin/ws-repos
    wrapProgram $out/bin/ws-repos \
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
    description = "Clone-or-pull git repos into ~/workspaces by a governed <host>/<org>/<repo> convention (a POSIX-shell port of strategy-coach/workspaces' mGit pattern), with VS Code multi-root *.mgit.code-workspace symlinking and a status report";
    mainProgram = "ws-repos";
  };
}
