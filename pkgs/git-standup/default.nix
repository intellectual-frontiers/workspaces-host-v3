{ pkgs }:

pkgs.stdenvNoCC.mkDerivation {
  pname = "git-standup";
  version = "1.0.0";
  src = ./.;
  dontUnpack = true;

  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    runHook preInstall
    install -Dm755 ${./git-standup} $out/bin/git-standup
    wrapProgram $out/bin/git-standup \
      --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.git pkgs.coreutils ]}
    runHook postInstall
  '';

  meta = {
    description = "List your commits since your last working day, across one or more git repos";
    mainProgram = "git-standup";
  };
}
