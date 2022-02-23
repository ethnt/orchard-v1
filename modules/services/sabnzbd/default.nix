{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.sabnzbd;
in {
  options.orchard.services.sabnzbd = {
    enable = mkEnableOption "Enable SABnzbd";
    port = mkOption {
      type = types.port;
      default = 8080;
    };
    openFirewall = mkOption {
      type = types.bool;
      default = false;
    };
    user = mkOption {
      type = types.str;
      default = "sabnzbd";
    };
    group = mkOption {
      type = types.str;
      default = "sabnzbd";
    };
  };

  config = mkIf cfg.enable {
    services.sabnzbd = { inherit (cfg) enable user group; };

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
      allowedUDPPorts = [ cfg.port ];
    };
  };
}
