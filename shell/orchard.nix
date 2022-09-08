{ pkgs, inputs, ... }:
let
  setEnvironmentVariable = var: key: ''
    export ${var}=$(${pkgs.sops}/bin/sops -d --extract '["${key}"]' ./secrets.yaml)
  '';
in {
  _file = toString ./.;

  devshell.startup.load_profiles = pkgs.lib.mkForce (pkgs.lib.noDepEntry ''
    _PATH=''${PATH}
    for file in "$DEVSHELL_DIR/etc/profile.d/"*.sh; do
      [[ -f "$file" ]] && source "$file"
    done
    export PATH=''${_PATH}
    unset _PATH

    ${setEnvironmentVariable "AWS_ACCESS_KEY_ID" "aws_access_key_id"}
    ${setEnvironmentVariable "AWS_SECRET_ACCESS_KEY" "aws_secret_access_key"}

    export NIXOPS_DEPLOYMENT="orchard"
    export NIXOPS_STATE="./state.nixops"

    export SOPS_AGE_KEY_DIR="$HOME/.config/sops/age"
  '');

  commands = let addPackage = category: package: { inherit package category; };
  in [
    (addPackage "runtime" pkgs.nixUnstable)
    (addPackage "runtime" pkgs.cachix)

    (addPackage "development" pkgs.git-crypt)
    (addPackage "development" pkgs.dhall)

    {
      package = inputs.sops-nix.defaultPackage.${pkgs.system};
      category = "development";
      help = "SOPS tool for initializing GPG keys";
    }

    (addPackage "code" pkgs.nixfmt)
    (addPackage "code" pkgs.statix)

    (addPackage "deployment" pkgs.nixopsUnstable)
  ];
}
