{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.prometheus-snmp-exporter;
in {
  options.orchard.services.prometheus-snmp-exporter = {
    enable = mkEnableOption "Enable the Prometheus SNMP exporter";
    host = mkOption { type = types.str; };
    port = mkOption {
      type = types.port;
      default = 9116;
    };
    openFirewall = mkOption {
      type = types.bool;
      default = false;
    };
    configurationFile = mkOption { type = types.path; };
  };

  config = mkIf cfg.enable {
    environment.etc."snmp_exporter/snmp.yml" = {
      source = cfg.configurationFile;
    };

    services.prometheus.exporters.snmp = mkIf cfg.enable {
      inherit (cfg) enable port;
      configurationPath = "/etc/snmp_exporter/snmp.yml";
    };

    networking.firewall =
      mkIf cfg.openFirewall { allowedTCPPorts = [ cfg.port ]; };
  };
}
