{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.prometheus;
in {
  options.orchard.services.prometheus = {
    enable = mkEnableOption "Enable Prometheus";
    host = mkOption { type = types.str; };
    port = mkOption {
      type = types.port;
      default = 9001;
    };
    openFirewall = mkOption {
      type = types.bool;
      default = false;
    };
    scrapers = mkOption {
      type = types.listOf types.anything;
      default = [ ];
    };
  };

  config = mkIf cfg.enable {
    services.prometheus = {
      inherit (cfg) enable port;

      scrapeConfigs = cfg.scrapers;
      extraFlags = [ "--log.level=debug" ];
    };

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
      allowedUDPPorts = [ cfg.port ];
    };
  };
}
