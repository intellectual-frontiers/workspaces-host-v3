{ pkgs }:

pkgs.stdenvNoCC.mkDerivation {
  pname = "doctor";
  version = "1.0.0";
  src = ./.;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 ${./doctor} $out/bin/doctor
    runHook postInstall
  '';

  meta = {
    # Deliberately NOT wrapped with a fixed PATH (unlike this repo's other
    # pkgs/* tools): doctor's whole job is to report on the *caller's*
    # live environment (what's actually on PATH after `home-manager
    # switch`), so wrapping it with its own PATH would make every check
    # pass unconditionally and defeat the point.
    description = "Slim health check for a workspaces-host-v3 provisioned environment";
    mainProgram = "doctor";
  };
}
