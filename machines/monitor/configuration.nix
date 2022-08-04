{ config, lib, pkgs, resources, nodes, ... }:
let aws = import ../../config/aws.nix;
in {
  deployment = {
    targetEnv = "ec2";
    ec2 = {
      inherit (aws) region;

      instanceType = "t3.micro";
      keyPair = resources.ec2KeyPairs.deployment-key;
      securityGroups = [ resources.ec2SecurityGroups.monitor-security-group ];
      ebsBoot = true;
      ebsInitialRootDiskSize = 128;
      elasticIPv4 = resources.elasticIPs.monitor-elastic-ip;
    };
  };

  sops = {
    secrets = { tailscale_auth_key = { sopsFile = ./secrets.yaml; }; };
  };

  networking.firewall.enable = lib.mkForce false;

  orchard = {
    services = {
      tailscale = {
        enable = true;
        openFirewall = true;
        authKeyFile = config.sops.secrets.tailscale_auth_key.path;
        hostname = "monitor";
        namespace = "orchard";
      };

      nginx = {
        enable = true;
        fqdn = "monitor.orchard.computer";
        acme.email = "admin@orchard.computer";
        virtualHosts = {
          "grafana.orchard.computer" = {
            http2 = true;

            addSSL = true;
            enableACME = true;

            locations."/" = {
              proxyPass = "http://${config.orchard.services.grafana.addr}:${
                  toString config.orchard.services.grafana.port
                }";
            };
          };
        };
      };

      grafana = {
        enable = true;
        domain = "grafana.orchard.computer";
        addr = "0.0.0.0";
        openFirewall = true;
        provisioning = {
          sources = [
            {
              name = "Prometheus";
              type = "prometheus";
              access = "proxy";
              url =
                "http://${nodes.monitor.config.orchard.services.tailscale.fqdn}:${
                  toString config.orchard.services.prometheus.port
                }";
            }
            {
              name = "Loki";
              type = "loki";
              access = "proxy";
              url =
                "http://${nodes.monitor.config.orchard.services.tailscale.fqdn}:${
                  toString config.orchard.services.loki.port
                }";
            }
          ];
          dashboards = [
            {
              name = "Nodes";
              options.path = ./grafana/dashboards/nodes.json;
            }
            {
              name = "Nginx";
              options.path = ./grafana/dashboards/nginx.json;
            }
            {
              name = "APC UPS";
              options.path = ./grafana/dashboards/apcupsd.json;
            }
            {
              name = "Smokeping";
              options.path = ./grafana/dashboards/smokeping.json;
            }
          ];
        };
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
          host = nodes.monitor.config.orchard.services.loki.host;
          port = nodes.monitor.config.orchard.services.loki.port;
        };
      };

      prometheus = {
        enable = true;
        host = "monitor.orchard.computer";
        openFirewall = true;
        scrapers = [
          {
            job_name = "monitor";
            static_configs = [{
              targets = [
                "${nodes.monitor.config.orchard.services.tailscale.fqdn}:${
                  toString
                  nodes.monitor.config.orchard.services.prometheus-node-exporter.port
                }"
              ];
            }];
          }
          {
            job_name = "gateway";
            static_configs = [{
              targets = [
                "${nodes.gateway.config.orchard.services.tailscale.fqdn}:${
                  toString
                  nodes.gateway.config.orchard.services.prometheus-node-exporter.port
                }"
              ];
            }];
          }
          {
            job_name = "htpc";
            static_configs = [{
              targets = [
                "${nodes.htpc.config.orchard.services.tailscale.fqdn}:${
                  toString
                  nodes.htpc.config.orchard.services.prometheus-node-exporter.port
                }"
              ];
            }];
          }
          {
            job_name = "errata";
            static_configs = [{
              targets = [
                "${nodes.errata.config.orchard.services.tailscale.fqdn}:${
                  toString
                  nodes.errata.config.orchard.services.prometheus-node-exporter.port
                }"
              ];
            }];
          }
          {
            job_name = "matrix";
            static_configs = [{
              targets = [
                "${nodes.matrix.config.orchard.services.tailscale.fqdn}:${
                  toString
                  nodes.matrix.config.orchard.services.prometheus-node-exporter.port
                }"
              ];
            }];
          }
          {
            job_name = "portal";
            static_configs = [{
              targets = [
                "${nodes.portal.config.orchard.services.tailscale.fqdn}:${
                  toString
                  nodes.portal.config.orchard.services.prometheus-node-exporter.port
                }"
              ];
            }];
          }
          {
            job_name = "pfsense";
            static_configs =
              [{ targets = [ "metrics.satan.orchard.computer" ]; }];
          }
          {
            job_name = "gateway_nginx";
            static_configs = [{
              targets = [
                "${nodes.gateway.config.orchard.services.tailscale.fqdn}:${
                  toString
                  nodes.gateway.config.orchard.services.prometheus-nginx-exporter.port
                }"
              ];
            }];
          }
          {
            job_name = "monitor_nginx";
            static_configs = [{
              targets = [
                "${nodes.monitor.config.orchard.services.tailscale.fqdn}:${
                  toString
                  nodes.monitor.config.orchard.services.prometheus-nginx-exporter.port
                }"
              ];
            }];
          }
          {
            job_name = "matrix_nginx";
            static_configs = [{
              targets = [
                "${nodes.matrix.config.orchard.services.tailscale.fqdn}:${
                  toString
                  nodes.matrix.config.orchard.services.prometheus-nginx-exporter.port
                }"
              ];
            }];
          }
          {
            job_name = "portal_nginx";
            static_configs = [{
              targets = [
                "${nodes.portal.config.orchard.services.tailscale.fqdn}:${
                  toString
                  nodes.portal.config.orchard.services.prometheus-nginx-exporter.port
                }"
              ];
            }];
          }
          {
            job_name = "apcupsd";
            static_configs = [{
              targets = [
                "${nodes.errata.config.orchard.services.tailscale.fqdn}:${
                  toString
                  nodes.errata.config.orchard.services.prometheus-apcupsd-exporter.port
                }"
              ];
            }];
          }
          {
            job_name = "snmp_pfsense";
            static_configs = [{ targets = [ "192.168.1.1" ]; }];
            metrics_path = "/snmp";
            params = { module = [ "pfsense" ]; };
            # scrape_interval = "10s";
            # scrape_timeout = "5s";
            relabel_configs = [
              {
                source_labels = [ "__address__" ];
                target_label = "__param_target";
              }
              {
                source_labels = [ "__param_target" ];
                target_label = "instance";
              }
              {
                target_label = "__address__";
                replacement =
                  "${nodes.errata.config.orchard.services.tailscale.fqdn}:${
                    toString
                    nodes.errata.config.orchard.services.prometheus-snmp-exporter.port
                  }";
              }
            ];
          }
          # {
          #   job_name = "smokeping";
          #   static_configs = [{
          #     targets = [
          #       "${nodes.errata.config.orchard.services.tailscale.fqdn}:${
          #         toString
          #         nodes.errata.config.orchard.services.prometheus-smokeping-exporter.port
          #       }"
          #     ];
          #   }];
          # }
        ];
      };

      prometheus-node-exporter = {
        enable = true;
        host = "monitor.orchard.computer";
        openFirewall = true;
      };

      prometheus-nginx-exporter = {
        enable = true;
        scrapeUri = "http://monitor.orchard.computer/stub_status";
        openFirewall = true;
      };

      restic = {
        enable = true;
        backupName = "monitor";
        paths = [ "/var/lib" ];
        passwordFile = config.sops.secrets.backup_password.path;
        s3 = {
          bucketName = resources.s3Buckets.monitor-backups-bucket.name;
          credentialsFile = config.sops.secrets.aws_credentials.path;
        };
      };
    };
  };
}
