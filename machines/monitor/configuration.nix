{ config, pkgs, resources, nodes, ... }:
let aws = import ../../config/aws.nix;
in {
  deployment = {
    targetEnv = "ec2";
    ec2 = {
      inherit (aws) region;

      instanceType = "t3.small";
      keyPair = resources.ec2KeyPairs.deployment-key;
      securityGroups = [
        resources.ec2SecurityGroups.ssh-security-group
        resources.ec2SecurityGroups.tailscale-security-group
        resources.ec2SecurityGroups.http-security-group
        resources.ec2SecurityGroups.prometheus-security-group
        resources.ec2SecurityGroups.prometheus-node-exporter-security-group
      ];
      ebsBoot = true;
      ebsInitialRootDiskSize = 50;
    };
  };

  sops.secrets = { grafana_environment_file = { sopsFile = ./secrets.yaml; }; };

  orchard = {
    services = {
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
                  notes.monitor.config.orchard.services.prometheus-exporter.node.port
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

      grafana = {
        enable = true;
        domain = "grafana.orchard.computer";

        nginx = {
          enable = true;
          host = config.orchard.services.grafana.domain;
        };

        environmentFile = config.sops.secrets.grafana_environment_file.path;

        provisioning = {
          sources = [{
            name = "Prometheus";
            type = "prometheus";
            access = "proxy";
            url = "http://${config.orchard.services.prometheus.host}:${
                toString config.orchard.services.prometheus.port
              }";
          }];

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
