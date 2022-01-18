{ config, pkgs, resources, nodes, ... }:
let aws = import ../../config/aws.nix;
in {
  deployment = {
    targetEnv = "ec2";
    ec2 = {
      inherit (aws) region;

      instanceType = "t3.small";
      keyPair = resources.ec2KeyPairs.deployment-key;
      associatePublicIpAddress = true;
      subnetId = resources.vpcSubnets.public-subnet;
      securityGroupIds =
        [ resources.ec2SecurityGroups.monitor-security-group.name ];
      ebsBoot = true;
      ebsInitialRootDiskSize = 50;
    };
  };

  sops.secrets = {
    grafana_environment_file = { sopsFile = ./secrets.yaml; };
    nebula_ca_cert = { sopsFile = ../secrets.yaml; };
    nebula_host_key = { sopsFile = ./secrets.yaml; };
    nebula_host_cert = { sopsFile = ./secrets.yaml; };
  };

  orchard = {
    services = {
      nebula = {
        enable = true;
        caCert = config.sops.secrets.nebula_ca_cert.path;
        hostKey = config.sops.secrets.nebula_host_key.path;
        hostCert = config.sops.secrets.nebula_host_cert.path;
        staticHostMap = {
          "10.11.12.1" =
            [ "${nodes.networking.config.networking.publicIPv4}:4242" ];
        };
        lighthouses = [ "10.11.12.1" ];
      };

      nginx = {
        enable = true;
        acme.email = "ethan.turkeltaub+orchard-computer@hey.com";
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
                "${nodes.monitor.config.orchard.services.prometheus-exporter.host}:${
                  toString
                  nodes.monitor.config.orchard.services.prometheus-exporter.node.port
                }"
              ];
            }];
          }
          {
            job_name = "builder";
            static_configs = [{
              targets = [
                "${nodes.builder.config.orchard.services.prometheus-exporter.host}:${
                  toString
                  nodes.builder.config.orchard.services.prometheus-exporter.node.port
                }"
              ];
            }];
          }
          {
            job_name = "networking";
            static_configs = [{
              targets = [
                "${nodes.networking.config.orchard.services.prometheus-exporter.host}:${
                  toString
                  nodes.networking.config.orchard.services.prometheus-exporter.node.port
                }"
              ];
            }];
          }
          {
            job_name = "bastion";
            static_configs = [{
              targets = [
                "${nodes.bastion.config.orchard.services.prometheus-exporter.host}:${
                  toString
                  nodes.bastion.config.orchard.services.prometheus-exporter.node.port
                }"
              ];
            }];
          }

          {
            job_name = "blocky";
            static_configs = [{ targets = [ "blocky.orchard.computer:80" ]; }];
          }
        ];
      };

      prometheus-exporter = {
        enable = true;
        host = "monitor.orchard.computer";
        node = {
          enable = true;
          openFirewall = true;
        };
      };

      loki = {
        enable = true;
        host = "monitor.orchard.computer";
        openFirewall = true;
      };

      promtail = {
        enable = true;
        host = "monitor.orchard.computer";
        lokiServerConfiguration = {
          host = nodes.monitor.config.orchard.services.loki.host;
          port = nodes.monitor.config.orchard.services.loki.port;
        };
      };

      grafana = {
        enable = true;
        domain = "grafana.orchard.computer";

        nginx = {
          enable = true;
          host = config.orchard.services.grafana.domain;
        };

        environmentFile = config.sops.secrets.grafana_environment_file.path;

        provisioning = {
          sources = [
            {
              name = "Prometheus";
              type = "prometheus";
              access = "proxy";
              url = "http://${config.orchard.services.prometheus.host}:${
                  toString config.orchard.services.prometheus.port
                }";
            }
            {
              name = "Loki";
              type = "loki";
              access = "proxy";
              url = "http://${config.orchard.services.loki.host}:${
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
