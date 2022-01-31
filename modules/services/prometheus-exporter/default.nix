{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.orchard.services.prometheus-exporter;
  firewallFilter = e: (if e.openFirewall then e.port else null);
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
    apcupsd = mkOption {
      type = types.submodule {
        options = {
          enable = mkEnableOption "Enable the APC UPS exporter";
          port = mkOption {
            type = types.port;
            default = 9162;
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
      apcupsd = mkIf cfg.apcupsd.enable {
        enable = true;
        port = cfg.apcupsd.port;
      };
    };

    networking.firewall =
      let ports = map firewallFilter [ cfg.node cfg.apcupsd ];
      in {
        allowedTCPPorts = ports;
        allowedUDPPorts = ports;
      };
  };
}
