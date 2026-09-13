{ pkgs, ... }:

{
  # Nix itself already pins a reproducible version for every tool this
  # setup provides, Java included, so a second version manager (SDKMAN!,
  # etc.) on top of it would just duplicate that job. This installs a
  # JDK + Maven directly from nixpkgs, unconditionally, like every other
  # tool here, rather than a version manager an engineer has to
  # separately invoke.
  home.packages = [
    pkgs.jdk
    pkgs.maven
  ];

  home.sessionVariables.JAVA_HOME = "${pkgs.jdk.home}";
}
