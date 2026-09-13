{ config, lib, pkgs, ... }:

let
  cfg = config.workspacesHost.secrets;

  secretModule = lib.types.submodule {
    options = {
      sopsFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to the sops-encrypted file holding this secret.";
      };
      path = lib.mkOption {
        type = lib.types.str;
        description = ''
          Where to write the decrypted plaintext, relative to
          `$XDG_STATE_HOME/workspaces-host/secrets` (never inside the Nix
          store, never world-readable - written at activation time, not
          build time).
        '';
      };
      extractKey = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "data";
        description = ''
          Which top-level key to pull the bare value from before writing
          it out. `sops --encrypt` wraps unstructured input under a
          `data` key by convention; set to `null` if the encrypted file
          is a real multi-key document and the raw decrypted output is
          wanted instead of one extracted field.
        '';
      };
    };
  };

  secretsStateDir = "${config.xdg.stateHome}/workspaces-host/secrets";

  decryptOne = name: secret:
    let
      extractArg = lib.optionalString (secret.extractKey != null)
        ''--extract '["${secret.extractKey}"]' '';
    in
    ''
      mkdir -p "$(dirname "${secretsStateDir}/${secret.path}")"
      ${pkgs.sops}/bin/sops --decrypt ${extractArg}"${secret.sopsFile}" > "${secretsStateDir}/${secret.path}.tmp"
      chmod 600 "${secretsStateDir}/${secret.path}.tmp"
      mv "${secretsStateDir}/${secret.path}.tmp" "${secretsStateDir}/${secret.path}"
    '';
in
{
  options.workspacesHost.secrets = lib.mkOption {
    type = lib.types.attrsOf secretModule;
    default = { };
    description = ''
      Declarative, *advanced*, sops-encrypted secrets - for anyone who
      specifically wants field-level encryption at rest for a given
      credential. Most people don't need this: see
      `~/.config/workspaces-host/credentials` and `workspaces-host-update`
      (README's "Setting up your credentials" section) for the
      recommended default - a plain `KEY=value` file, protected by
      ordinary file permissions, no `age`/`sops` steps at all.

      Each secret declared here is decrypted at *activation* time
      (`home-manager switch`, every run - never at build/eval time) into
      `$XDG_STATE_HOME/workspaces-host/secrets/`, so the plaintext never
      lands in the world-readable Nix store. This module intentionally
      does not manage decryption key material itself, per Constitution
      Principle III: provisioning the key is a deliberate, separate,
      human action.
    '';
    example = lib.literalExpression ''
      {
        "github-token" = {
          sopsFile = ./secrets/github-token.enc.yaml;
          path = "env/GITHUB_TOKEN";
        };
      }
    '';
  };

  config = lib.mkIf (cfg != { }) {
    home.packages = [ pkgs.sops pkgs.age ];

    # Raw bash rather than home-manager's `run` helper: decrypting each
    # secret is a short multi-statement pipeline, not a single command.
    home.activation.decryptWorkspacesHostSecrets = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "${secretsStateDir}"
      chmod 700 "${secretsStateDir}"
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList decryptOne cfg)}
    '';
  };
}
