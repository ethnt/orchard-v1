{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.prometheus-apcupsd-exporter;
in {
  options.orchard.services.prometheus-apcupsd-exporter = {
    enable = mkEnableOption "Enable the Prometheus apcupsd exporter";
    host = mkOption { type = types.str; };
    port = mkOption {
      type = types.port;
      default = 9162;
    };
    openFirewall = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    services.prometheus.exporters.apcupsd =
      mkIf cfg.enable { inherit (cfg) enable port; };

    networking.firewall =
      mkIf cfg.openFirewall { allowedTCPPorts = [ cfg.port ]; };
  };
}
