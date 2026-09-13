{ pkgs }:

pkgs.stdenvNoCC.mkDerivation {
  pname = "pgpass";
  version = "1.0.0";
  src = ./.;
  dontUnpack = true;

  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    runHook preInstall
    install -Dm755 ${./pgpass} $out/bin/pgpass
    wrapProgram $out/bin/pgpass \
      --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.jq pkgs.gnused pkgs.gawk pkgs.coreutils ]}
    runHook postInstall
  '';

  meta = {
    description = "Look up PostgreSQL connections declared in ~/.pgpass by id (env vars, psql command, or connection URL)";
    mainProgram = "pgpass";
  };
}
