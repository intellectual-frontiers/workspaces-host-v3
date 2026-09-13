{ pkgs }:

pkgs.stdenvNoCC.mkDerivation {
  pname = "scaffold-agent-harness";
  version = "1.0.0";
  src = ./.;
  dontUnpack = true;

  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    runHook preInstall
    install -Dm755 ${./scaffold-agent-harness} $out/bin/scaffold-agent-harness
    mkdir -p $out/share/workspaces-host
    cp -r ${../../templates/agent-harness} $out/share/workspaces-host/agent-harness
    wrapProgram $out/bin/scaffold-agent-harness \
      --set SCAFFOLD_TEMPLATE_DIR "$out/share/workspaces-host/agent-harness" \
      --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.coreutils pkgs.findutils ]}
    runHook postInstall
  '';

  meta = {
    description = "Materialize the workspaces-host-v3 agent-harness convention (AGENTS.md, .mcp.json, .claude/*) into a project, without overwriting existing files";
    mainProgram = "scaffold-agent-harness";
  };
}
