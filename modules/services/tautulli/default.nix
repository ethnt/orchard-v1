{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.tautulli;
in {
  options.orchard.services.tautulli = {
    enable = mkEnableOption "Enable Tautulli";
    port = mkOption {
      type = types.port;
      default = 8181;
    };
    user = mkOption {
      type = types.str;
      default = "plexpy";
    };
    group = mkOption {
      type = types.str;
      default = "nogroup";
    };
    openFirewall = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    services.tautulli = { inherit (cfg) enable port user group; };

    networking.firewall = {
      allowedTCPPorts = [ cfg.port ];
      allowedUDPPorts = [ cfg.port ];
    };
  };
}
