{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.grafana;
in {
  options.orchard.services.grafana = {
    enable = mkEnableOption "Enable Grafana";
    domain = mkOption {
      type = types.str;
      default = "localhost";
    };
    port = mkOption {
      type = types.port;
      default = 2342;
    };
    addr = mkOption {
      type = types.str;
      default = "127.0.0.1";
    };
    openFirewall = mkOption {
      type = types.bool;
      default = false;
    };
    environmentFile = mkOption {
      type = types.str;
      description =
        "Environment file to be used in the Grafana systemd service";
    };
    provisioning = mkOption {
      type = types.submodule {
        options = {
          sources = mkOption { type = types.anything; };
          notifiers = mkOption { type = types.anything; };
        };
      };
    };
    nginx = mkOption {
      type = types.submodule {
        options = {
          enable = mkEnableOption "Enable Nginx for Grafana";
          host = mkOption { type = types.str; };
          port = mkOption { type = types.port; };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    services.grafana = {
      inherit (cfg) enable domain port addr;

      provision = {
        enable = true;
        datasources = cfg.provisioning.sources;
        notifiers = cfg.provisioning.notifiers;
      };
    };

    systemd.services.grafana = {
      serviceConfig = { EnvironmentFile = cfg.environmentFile; };
    };

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
      allowedUDPPorts = [ cfg.port ];
    };

    services.nginx = mkIf cfg.nginx.enable {
      virtualHosts.${cfg.nginx.host} = {
        http2 = true;
        addSSL = true;
        enableACME = true;

        locations."/" = {
          proxyPass = "http://${cfg.addr}:${toString cfg.port}";
        };
      };
    };
  };
}
