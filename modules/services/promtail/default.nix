{ config, pkgs, lib, ... }:

with lib;

let cfg = config.orchard.services.promtail;
in {
  options.orchard.services.promtail = {
    enable = mkEnableOption "Enable Promtail log shipping";
    port = mkOption {
      type = types.port;
      default = 28183;
    };
    host = mkOption { type = types.str; };
    lokiServerConfiguration = mkOption {
      type = types.submodule {
        options = {
          host = mkOption { type = types.str; };
          port = mkOption { type = types.port; };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    services.promtail = {
      enable = true;
      configuration = {
        server = {
          http_listen_port = cfg.port;
          grpc_listen_port = 0;
        };

        positions = { filename = "/tmp/positions.yaml"; };

        clients = [{
          url = "http://${cfg.lokiServerConfiguration.host}:${
              toString cfg.lokiServerConfiguration.port
            }/loki/api/v1/push";
        }];

        scrape_configs = [{
          job_name = "journal";
          journal = {
            max_age = "12h";
            labels = {
              job = "systemd-journal";
              host = cfg.host;
            };
          };
          relabel_configs = [{
            source_labels = [ "__journal__systemd_unit" ];
            target_label = "unit";
          }];
        }];
      };
    };
  };
}
