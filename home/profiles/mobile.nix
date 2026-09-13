{ pkgs, ... }:

{
  # Mobile development: device/emulator interaction tooling and the file
  # watcher React Native's tooling expects, on top of the shared base
  # profile. Full Android SDK / Xcode toolchains are deliberately out of
  # scope here (huge, licensing-encumbered, and platform-specific in ways
  # that don't fit a single cross-platform Nix module cleanly) - install
  # those via Android Studio / Xcode as usual; this profile covers what's
  # cleanly packageable.
  home.packages = with pkgs; [
    android-tools # adb, fastboot
    watchman
  ];
}
