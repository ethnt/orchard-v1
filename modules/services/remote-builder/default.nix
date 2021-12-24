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
  };

  config = mkIf cfg.enable {
    boot.binfmt.emulatedSystems = cfg.emulatedSystems;

    nix.trustedUsers = [ "builder" ];

    users.extraUsers.builder = {
      createHome = false;
      isNormalUser = false;
      extraGroups = [ "wheel" ];
      group = "users";
      isSystemUser = true;
    };
  };
}
