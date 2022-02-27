{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.hydra;
in {
  options.orchard.services.hydra = {
    enable = mkEnableOption "Enable Hydra CI";
    url = mkOption {
      type = types.str;
      example = "http://localhost:3000";
    };
    email = mkOption { type = types.str; };
  };

  config = mkIf cfg.enable {
    services.hydra = {
      enable = true;
      hydraURL = cfg.url;
      notificationSender = cfg.email;
      buildMachinesFiles = [ ];
      useSubstitutes = true;
    };
  };
}
