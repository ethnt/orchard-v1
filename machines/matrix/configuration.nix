{ config, lib, pkgs, resources, nodes, ... }:
let aws = import ../../config/aws.nix;
in {
  deployment = {
    targetEnv = "ec2";
    ec2 = {
      inherit (aws) region;

      instanceType = "t3.micro";
      keyPair = resources.ec2KeyPairs.deployment-key;
      securityGroups = [ resources.ec2SecurityGroups.matrix-security-group ];
      ebsBoot = true;
      ebsInitialRootDiskSize = 64;
      elasticIPv4 = resources.elasticIPs.matrix-elastic-ip;
    };
  };

  sops = {
    secrets = {
      miniflux_credentials = { sopsFile = ./secrets.yaml; };
      tailscale_auth_key = { sopsFile = ./secrets.yaml; };
      hercules_binary_caches = {
        sopsFile = ./secrets.yaml;
        owner = config.users.users.hercules-ci-agent.name;
        mode = "0440";
      };
      hercules_cluster_join_token = {
        sopsFile = ./secrets.yaml;
        owner = config.users.users.hercules-ci-agent.name;
        mode = "0440";
      };
    };
  };

  orchard = {
    services = {
      tailscale = {
        enable = true;
        openFirewall = true;
        authKeyFile = config.sops.secrets.tailscale_auth_key.path;
        hostname = "matrix";
        namespace = "orchard";
      };

      docker.enable = true;

      remote-builder = {
        enable = true;
        emulatedSystems = [ "aarch64-linux" ];
        buildUserPublicKeyFile = ./remote-builder/builder.pub;
      };

      promtail = {
        enable = true;
        host = "matrix";
        lokiServerConfiguration = {
          host = nodes.monitor.config.orchard.services.loki.host;
          port = nodes.monitor.config.orchard.services.loki.port;
        };
      };

      prometheus-node-exporter = {
        enable = true;
        host = "matrix.orchard.computer";
        openFirewall = true;
      };

      prometheus-nginx-exporter = {
        enable = true;
        scrapeUri = "http://matrix.orchard.computer/stub_status";
        openFirewall = true;
      };

      filebrowser = {
        enable = true;
        srvDir = "/var/www/e10.land";
      };

      nginx = {
        enable = true;
        fqdn = "matrix.orchard.computer";
        acme.email = "admin@orchard.computer";

        virtualHosts = {
          "e10.land" = {
            forceSSL = true;
            enableACME = true;

            locations."/" = {
              root = "/var/www/e10.land";
              extraConfig = ''
                autoindex on;
                fancyindex on;
              '';
            };
          };

          "filebrowser.e10.land" = {
            http2 = true;

            forceSSL = true;
            enableACME = true;

            extraConfig = ''
              client_max_body_size 100M;
            '';

            locations."/" = {
              proxyPass =
                "http://${nodes.matrix.config.orchard.services.tailscale.fqdn}:${
                  toString nodes.htpc.config.orchard.services.filebrowser.port
                }";
              proxyWebsockets = true;
            };
          };

          "feeds.orchard.computer" = {
            http2 = true;

            forceSSL = true;
            enableACME = true;

            locations."/" = {
              proxyPass =
                "http://${nodes.matrix.config.orchard.services.tailscale.fqdn}:${
                  toString nodes.htpc.config.orchard.services.miniflux.port
                }";
              proxyWebsockets = true;
            };
          };
        };
      };

      restic = {
        enable = true;
        backupName = "matrix";
        paths = [ "/var/lib" ];
        passwordFile = config.sops.secrets.backup_password.path;
        s3 = {
          bucketName = resources.s3Buckets.matrix-backups-bucket.name;
          credentialsFile = config.sops.secrets.aws_credentials.path;
        };
      };

      miniflux = {
        enable = true;
        credentialsFile = config.sops.secrets.miniflux_credentials.path;
      };

      hercules-ci-agent = {
        enable = false;
        clusterJoinTokenPath =
          config.sops.secrets.hercules_cluster_join_token.path;
        binaryCachesPath = config.sops.secrets.hercules_binary_caches.path;
        labels = { agent.source = "flake"; };
      };
    };
  };
}
