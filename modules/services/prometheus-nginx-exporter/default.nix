{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.prometheus-nginx-exporter;
in {
  options.orchard.services.prometheus-nginx-exporter = {
    enable = mkEnableOption "Enable the Prometheus Nginx exporter";
    host = mkOption { type = types.str; };
    port = mkOption {
      type = types.port;
      default = 9113;
    };
    openFirewall = mkOption {
      type = types.bool;
      default = false;
    };
    scrapeUri = mkOption { type = types.str; };
    sslVerify = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    services.prometheus.exporters.nginx =
      mkIf cfg.enable { inherit (cfg) enable scrapeUri sslVerify; };

    networking.firewall =
      mkIf cfg.openFirewall { allowedTCPPorts = [ cfg.port ]; };
  };
}
