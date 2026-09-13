{ pkgs, ... }:

{
  # Backend/service development: DB/cache clients and a compose-based
  # local-stack runner, on top of the shared base profile.
  home.packages = with pkgs; [
    postgresql
    redis
    docker-compose
    httpie
  ];
}
