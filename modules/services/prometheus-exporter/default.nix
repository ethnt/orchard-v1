{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.prometheus-exporter;
in {
  options.orchard.services.prometheus-exporter = {
    enable = mkEnableOption "Enable Prometheus exporters";
    host = mkOption { type = types.str; };
    node = mkOption {
      type = types.submodule {
        options = {
          enable = mkEnableOption "Enable the Prometheus node exporter";
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
      };
    };
  };

  config = mkIf cfg.enable {
    services.prometheus.exporters = mkIf cfg.enable {
      node = mkIf cfg.node.enable {
        enable = true;
        enabledCollectors = cfg.node.collectors;
        port = cfg.node.port;
      };
    };

    networking.firewall = mkIf cfg.node.openFirewall {
      allowedTCPPorts = [ cfg.node.port ];
      allowedUDPPorts = [ cfg.node.port ];
    };
  };
}
