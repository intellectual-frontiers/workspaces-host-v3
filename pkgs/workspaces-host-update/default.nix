{ pkgs }:

pkgs.stdenvNoCC.mkDerivation {
  pname = "workspaces-host-update";
  version = "1.0.0";
  src = ./.;
  dontUnpack = true;

  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    runHook preInstall
    install -Dm755 ${./workspaces-host-update} $out/bin/workspaces-host-update
    wrapProgram $out/bin/workspaces-host-update \
      --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.git pkgs.coreutils ]}
    runHook postInstall
  '';

  meta = {
    description = "Pull workspaces-host-v3, apply ~/.config/workspaces-host/credentials, re-activate, and run doctor";
    mainProgram = "workspaces-host-update";
  };
}
