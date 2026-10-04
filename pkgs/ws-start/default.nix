{ pkgs }:

pkgs.stdenvNoCC.mkDerivation {
  pname = "ws-start";
  version = "1.0.0";
  src = ./.;
  dontUnpack = true;

  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    runHook preInstall
    install -Dm755 ${./ws-start} $out/bin/ws-start
    wrapProgram $out/bin/ws-start \
      --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.gh pkgs.git pkgs.coreutils (import ../ws-repos { inherit pkgs; }) ]}
    runHook postInstall
  '';

  meta = {
    description = "Devcontainer postAttachCommand: authenticate gh (wiring it in as git's credential helper), adopt the checkout the editor opened into ~/workspaces, then run ws-repos ensure";
    mainProgram = "ws-start";
  };
}
