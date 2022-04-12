{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.prometheus-node-exporter;
in {
  options.orchard.services.prometheus-node-exporter = {
    enable = mkEnableOption "Enable the Prometheus node exporter";
    host = mkOption { type = types.str; };
    collectors = mkOption {
      type = types.listOf types.str;
      default = [ "systemd" "processes" ];
    };
    port = mkOption {
      type = types.port;
      default = 9002;
    };
    openFirewall = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    services.prometheus.exporters.node = mkIf cfg.enable {
      inherit (cfg) enable port;
      enabledCollectors = cfg.collectors;
    };

    networking.firewall =
      mkIf cfg.openFirewall { allowedTCPPorts = [ cfg.port ]; };
  };
}
