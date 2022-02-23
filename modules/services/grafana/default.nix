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
    # environmentFile = mkOption {
    #   type = types.str;
    #   description =
    #     "Environment file to be used in the Grafana systemd service";
    # };
    provisioning = mkOption {
      type = types.submodule {
        options = {
          sources = mkOption { type = types.anything; };
          dashboards = mkOption {
            type = types.listOf types.attrs;
            default = [ ];
          };
          notifiers = mkOption {
            type = types.listOf types.attrs;
            default = [ ];
          };
        };
      };
    };
    nginx = mkOption {
      type = types.submodule {
        options = {
          enable = mkEnableOption "Enable Nginx for Grafana";
          host = mkOption { type = types.str; };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    services.grafana = {
      inherit (cfg) enable domain port addr;

      package = pkgs.unstable.grafana;

      provision = {
        enable = true;
        datasources = cfg.provisioning.sources;
        dashboards = cfg.provisioning.dashboards;
        notifiers = cfg.provisioning.notifiers;
      };
    };

    # systemd.services.grafana = {
    #   serviceConfig = { EnvironmentFile = cfg.environmentFile; };
    # };

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
      allowedUDPPorts = [ cfg.port ];
    };
  };
}
