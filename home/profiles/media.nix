{ pkgs, ... }:

{
  # Local audio transcription (spec 026): `faster-whisper` is a
  # CTranslate2-based reimplementation of OpenAI Whisper, but its own
  # dependency closure (CTranslate2, ONNX Runtime, OpenBLAS) is real
  # weight every engineer would pay on every rebuild if this lived in
  # the base profile, for a capability only some repos need - the same
  # judgment call that already keeps `compliance`'s osquery/cnquery/
  # steampipe out of base. `ffmpeg` is `faster-whisper`'s real runtime
  # dependency: it decodes whatever container format an input file
  # actually arrives in before CTranslate2 ever sees raw PCM samples.
  #
  # Deliberately NOT baked into either published OCI image (spec 020/
  # 027) for the same weight reason - a real host or VM install turns
  # this on with `ws-persona activate media`.
  #
  # `faster-whisper` folds into home/tools.nix's one `python3.withPackages`
  # environment via `workspacesHost.extraPythonPackages`, rather than
  # declaring its own separate `python3` here - two different `python3`
  # derivations would collide in `home.packages`'s buildEnv the moment
  # this persona is combined with the (always-active) base profile.
  workspacesHost.extraPythonPackages = [ pkgs.python3Packages.faster-whisper ];

  home.packages = [ pkgs.ffmpeg ];
}
