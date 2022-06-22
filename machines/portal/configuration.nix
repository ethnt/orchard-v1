{ config, lib, pkgs, resources, nodes, ... }:
let aws = import ../../config/aws.nix;
in {
  deployment = {
    targetEnv = "ec2";
    ec2 = {
      inherit (aws) region;

      instanceType = "t3.small";
      keyPair = resources.ec2KeyPairs.deployment-key;
      securityGroups = [ resources.ec2SecurityGroups.portal-security-group ];
      ebsBoot = true;
      ebsInitialRootDiskSize = 64;
      elasticIPv4 = resources.elasticIPs.portal-elastic-ip;
    };
  };

  sops = {
    secrets = {
      nebula_host_key = { sopsFile = ./secrets.yaml; };
      nebula_host_cert = { sopsFile = ./secrets.yaml; };
      tailscale_auth_key = { sopsFile = ./secrets.yaml; };
    };
  };

  services.headscale = {
    enable = true;
    serverUrl = "https://headscale.orchard.computer:443";
    # privateKeyFile = config.sops.secrets.headscale_private_key.path;
    settings = { grpc_listen_addr = "127.0.0.1:50443"; };
    dns.baseDomain = "orchard";
  };

  # services.tailscale.enable = true;

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
          addr = "10.10.10.6";
          keyPath = config.sops.secrets.nebula_host_key.path;
          certPath = config.sops.secrets.nebula_host_cert.path;
        };
      };

      docker.enable = true;

      nginx = {
        enable = true;
        acme = { email = "admin@orchard.computer"; };
        virtualHosts = {
          "headscale.orchard.computer" = {
            enableACME = true;
            forceSSL = true;
            locations = {
              "/headscale." = {
                extraConfig = ''
                  grpc_pass grpc://${config.services.headscale.settings.grpc_listen_addr};
                '';
                priority = 1;
              };
              "/metrics" = {
                proxyPass = "http://127.0.0.1:9090";
                # extraConfig = ''
                #   allow 10.0.0.0/8;
                #   allow 100.64.0.0/16;
                #   deny all;
                # '';
                priority = 2;
              };
              "/" = {
                proxyPass =
                  "http://127.0.0.1:${toString config.services.headscale.port}";
                proxyWebsockets = true;
                extraConfig = ''
                  keepalive_requests          100000;
                  keepalive_timeout           160s;
                  proxy_buffering             off;
                  proxy_connect_timeout       75;
                  proxy_ignore_client_abort   on;
                  proxy_read_timeout          900s;
                  proxy_send_timeout          600;
                  send_timeout                600;
                '';
                priority = 99;
              };
            };
          };

          "overseerr.orchard.computer" = {
            http2 = true;

            addSSL = true;
            enableACME = true;

            locations."/" = {
              proxyPass =
                "http://${nodes.htpc.config.orchard.services.nebula.host.addr}:${
                  toString nodes.htpc.config.orchard.services.overseerr.port
                }";
              proxyWebsockets = true;
            };
          };
        };
      };
    };
  };
}
