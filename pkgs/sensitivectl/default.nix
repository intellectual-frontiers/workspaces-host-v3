{ pkgs }:

pkgs.stdenvNoCC.mkDerivation {
  pname = "sensitivectl";
  version = "1.0.0";
  src = ./.;
  dontUnpack = true;

  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    runHook preInstall
    install -Dm755 ${./sensitivectl} $out/bin/sensitivectl
    wrapProgram $out/bin/sensitivectl \
      --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.jq pkgs.rclone pkgs.coreutils ]}
    runHook postInstall
  '';

  meta = {
    description = "Back up/restore named local directories to/from an rclone remote, driven by a small JSON config";
    mainProgram = "sensitivectl";
  };
}
