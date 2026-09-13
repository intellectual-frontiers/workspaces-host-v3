{ pkgs, homeConfig }:

let
  cfg = homeConfig.config;
  configFile = name: cfg.xdg.configFile.${name}.source;
  # bash's config isn't under xdg.configFile - home-manager writes it as
  # plain dotfiles (~/.bashrc, ~/.bash_profile, ~/.profile),
  # unconditionally, once `programs.bash.enable` is on.
  dotfile = name: cfg.home.file.${name}.source;
in
pkgs.dockerTools.buildLayeredImage {
  name = "workspaces-host";
  tag = "latest";

  # Same closure as the host profile: the exact package set home-manager
  # decided this profile needs (bash, oh-my-posh, direnv, git, ws-repos,
  # doctor, and the core CLI toolset), plus cacert/bash/coreutils for a
  # usable minimal container.
  contents = cfg.home.packages ++ (with pkgs; [
    bashInteractive
    coreutils
    cacert
    dockerTools.fakeNss
  ]);

  extraCommands = ''
    mkdir -p root/.config/git root/.config/oh-my-posh root/.config/direnv/lib tmp
    cp ${dotfile ".bashrc"} root/.bashrc
    cp ${dotfile ".bash_profile"} root/.bash_profile
    cp ${dotfile ".profile"} root/.profile
    cp ${configFile "git/config"} root/.config/git/config
    cp ${configFile "oh-my-posh/config.json"} root/.config/oh-my-posh/config.json
    cp ${configFile "direnv/lib/hm-nix-direnv.sh"} root/.config/direnv/lib/hm-nix-direnv.sh
    chmod -R u+w root
  '';

  config = {
    Env = [
      "HOME=/root"
      "USER=root"
      "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    ];
    # `-l`: a login shell, guaranteeing the .bash_profile -> .bashrc
    # sourcing chain runs regardless of how the container is invoked.
    Cmd = [ "${pkgs.bashInteractive}/bin/bash" "-l" ];
    WorkingDir = "/root";
  };
}
