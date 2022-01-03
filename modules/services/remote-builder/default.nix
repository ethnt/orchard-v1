{ config, pkgs, lib, ... }:

with lib;

let cfg = config.orchard.services.remote-builder;
in {
  options.orchard.services.remote-builder = {
    enable = mkEnableOption "Enable the ability to be a remote builder";

    emulatedSystems = mkOption {
      type = types.listOf types.string;
      default = [ ];
    };

    buildUserKeyFile = mkOption { type = types.path; };
  };

  config = mkIf cfg.enable {
    boot.binfmt.emulatedSystems = cfg.emulatedSystems;

    nix.trustedUsers = [ "builder" ];

    users.extraUsers.builder = {
      createHome = false;
      isNormalUser = false;
      isSystemUser = true;
      extraGroups = [ "wheel" ];
      group = "users";
      openssh.authorizedKeys.keyFiles = [ cfg.buildUserKeyFile ];
    };
  };
}
