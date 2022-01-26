{ config, pkgs, resources, nodes, ... }: {
  deployment = { targetHost = "192.168.1.181"; };

  networking.privateIPv4 = "192.168.1.181";

  imports = [ ./hardware-configuration.nix ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  services.qemuGuest.enable = true;

  sops.secrets = {
    grafana_environment_file = { sopsFile = ./secrets.yaml; };
    pve_exporter_config_file = {
      mode = "0444";
      sopsFile = ./secrets.yaml;
    };
  };

  orchard = {
    services = {
      prometheus = {
        enable = true;
        host = "monitor.orchard.computer";
        openFirewall = true;

        scrapers = [
          {
            job_name = "monitor";
            static_configs = [{
              targets = [
                "${nodes.monitor.config.networking.privateIPv4}:${
                  toString
                  nodes.monitor.config.orchard.services.prometheus-exporter.node.port
                }"
              ];
            }];
          }
          {
            job_name = "bastion";
            static_configs = [{
              targets = [
                "${nodes.bastion.config.networking.privateIPv4}:${
                  toString
                  nodes.bastion.config.orchard.services.prometheus-exporter.node.port
                }"
              ];
            }];
          }
          {
            job_name = "unifi";
            static_configs = [{
              targets = [
                "${nodes.unifi.config.networking.privateIPv4}:${
                  toString
                  nodes.unifi.config.orchard.services.prometheus-exporter.node.port
                }"
              ];
            }];
          }
          {
            job_name = "htpc";
            static_configs = [{
              targets = [
                "${nodes.htpc.config.networking.privateIPv4}:${
                  toString
                  nodes.htpc.config.orchard.services.prometheus-exporter.node.port
                }"
              ];
            }];
          }
          {
            job_name = "pfsense";
            static_configs = [{ targets = [ "192.168.1.1:9002" ]; }];
          }
          {
            job_name = "arbor";
            static_configs = [{ targets = [ "192.168.1.93:9100" ]; }];
          }
          {
            job_name = "garden";
            static_configs = [{ targets = [ "192.168.1.159:9100" ]; }];
          }
          {
            job_name = "pve";
            metrics_path = "/pve";
            static_configs =
              [{ targets = [ "192.168.1.93" "192.168.1.159" ]; }];
            params = { module = [ "default" ]; };
            relabel_configs = [
              {
                source_labels = [ "__address" ];
                target_label = "__param_target";
              }
              {
                source_labels = [ "__param_target" ];
                target_label = "instance";
              }
              {
                target_label = "__address__";
                replacement = "${nodes.monitor.config.networking.privateIPv4}:${
                    toString
                    nodes.monitor.config.orchard.services.pve-exporter.port
                  }";
              }

            ];
          }
        ];
      };

      prometheus-exporter = {
        enable = true;
        host = "monitor";
        node = {
          enable = true;
          openFirewall = true;
        };
      };

      docker.enable = true;

      pve-exporter = {
        enable = true;
        configFile = config.sops.secrets.pve_exporter_config_file.path;
        openFirewall = true;
      };

      loki = {
        enable = true;
        host = "monitor.orchard.computer";
        openFirewall = true;
      };

      promtail = {
        enable = true;
        host = "monitor";
        lokiServerConfiguration = {
          host = nodes.monitor.config.networking.privateIPv4;
          port = nodes.monitor.config.orchard.services.loki.port;
        };
      };

      grafana = {
        enable = true;
        domain = "grafana.orchard.computer";
        addr = "0.0.0.0";

        openFirewall = true;

        environmentFile = config.sops.secrets.grafana_environment_file.path;

        provisioning = {
          sources = [
            {
              name = "Prometheus";
              type = "prometheus";
              access = "proxy";
              url = "http://${nodes.monitor.config.networking.privateIPv4}:${
                  toString config.orchard.services.prometheus.port
                }";
            }
            {
              name = "Loki";
              type = "loki";
              access = "proxy";
              url = "http://${nodes.monitor.config.networking.privateIPv4}:${
                  toString config.orchard.services.loki.port
                }";
            }
          ];

          notifiers = [{
            uid = "pushover";
            type = "pushover";
            name = "Pushover";
            settings = {
              apiToken = "$GF_PUSHOVER_API_TOKEN";
              userKey = "$GF_PUSHOVER_USER_KEY";
            };
          }];
        };
      };
    };
  };
}
