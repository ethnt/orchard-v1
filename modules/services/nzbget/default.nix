{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.nzbget;
in {
  options.orchard.services.nzbget = {
    enable = mkEnableOption "Enable NZBget";
    port = mkOption {
      type = types.port;
      default = 6789;
    };
    openFirewall = mkOption {
      type = types.bool;
      default = false;
    };
    user = mkOption {
      type = types.str;
      default = "nzbget";
    };
    group = mkOption {
      type = types.str;
      default = "nzbget";
    };
    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/nzbget";
    };
  };

  config = mkIf cfg.enable {
    services.nzbget = { inherit (cfg) enable user group; };

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
      allowedUDPPorts = [ cfg.port ];
    };
  };
}
