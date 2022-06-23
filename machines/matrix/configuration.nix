{ config, lib, pkgs, resources, nodes, ... }:
let aws = import ../../config/aws.nix;
in {
  deployment = {
    targetEnv = "ec2";
    ec2 = {
      inherit (aws) region;

      instanceType = "t3.small";
      keyPair = resources.ec2KeyPairs.deployment-key;
      securityGroups = [ resources.ec2SecurityGroups.matrix-security-group ];
      ebsBoot = true;
      ebsInitialRootDiskSize = 64;
      elasticIPv4 = resources.elasticIPs.matrix-elastic-ip;
    };
  };

  sops = {
    secrets = {
      nebula_host_key = { sopsFile = ./secrets.yaml; };
      nebula_host_cert = { sopsFile = ./secrets.yaml; };
      miniflux_credentials = { sopsFile = ./secrets.yaml; };
      tailscale_auth_key = { sopsFile = ./secrets.yaml; };
    };
  };

  orchard = {
    services = {
      tailscale = {
        enable = true;
        openFirewall = true;
        authKeyFile = config.sops.secrets.tailscale_auth_key.path;
      };

      nebula = {
        enable = true;
        network = {
          lighthouses = [ "10.10.10.1" ];
          staticHostMap = {
            "10.10.10.1" =
              [ "${nodes.gateway.config.networking.publicIPv4}:4242" ];
            "10.10.10.2" =
              [ "${nodes.gateway.config.networking.publicIPv4}:4343" ];
            "10.10.10.3" =
              [ "${nodes.gateway.config.networking.publicIPv4}:4444" ];
          };
        };
        host = {
          addr = "10.10.10.5";
          keyPath = config.sops.secrets.nebula_host_key.path;
          certPath = config.sops.secrets.nebula_host_cert.path;
        };
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
        acme.email = "admin@orchard.computer";

        virtualHosts = {
          "matrix.orchard.computer" = {
            locations."/stub_status" = {
              extraConfig = ''
                stub_status;
              '';
            };
          };

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
                "http://${nodes.matrix.config.orchard.services.nebula.host.addr}:${
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
                "http://${nodes.matrix.config.orchard.services.nebula.host.addr}:${
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
    };
  };
}
