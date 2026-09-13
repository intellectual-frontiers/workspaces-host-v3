{ pkgs }:

pkgs.stdenvNoCC.mkDerivation {
  pname = "ws-persona";
  version = "1.0.0";
  src = ./.;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 ${./ws-persona} $out/bin/ws-persona
    runHook postInstall
  '';

  meta = {
    # Deliberately NOT wrapped with a fixed PATH (same reasoning as
    # doctor): 'current' reports on the caller's own live PATH, so
    # wrapping it would make every persona look active (or inactive)
    # regardless of reality.
    description = "Discover workspace personas and check which look active";
    mainProgram = "ws-persona";
  };
}
