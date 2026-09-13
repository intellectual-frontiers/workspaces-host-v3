{ pkgs }:

pkgs.stdenvNoCC.mkDerivation {
  pname = "init-firewall";
  version = "1.0.0";
  src = ./.;
  dontUnpack = true;

  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    runHook preInstall
    install -Dm755 ${./init-firewall} $out/bin/init-firewall
    wrapProgram $out/bin/init-firewall \
      --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.iptables pkgs.ipset pkgs.getent pkgs.gawk pkgs.coreutils pkgs.curl ]}
    runHook postInstall
  '';

  meta = {
    description = "Default-deny outbound network egress except an allowlist of domains, modeled on Anthropic's reference Claude Code devcontainer firewall";
    mainProgram = "init-firewall";
  };
}
