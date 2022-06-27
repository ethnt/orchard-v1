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
      headscale_private_key = { sopsFile = ./secrets.yaml; };
      tailscale_auth_key = { sopsFile = ./secrets.yaml; };
    };
  };

  orchard = {
    services = {
      headscale = {
        enable = true;
        externalServerUrl = "https://headscale.orchard.computer:443";
        namespaces = [ "orchard" ];
        extraSettings = {
          ip_prefixes = [ "fd7a:115c:a1e0::/48" "100.64.0.0/10" ];
          metrics_listen_addr = "127.0.0.1:9090";
        };
        # privateKeyFile = config.sops.secrets.headscale_private_key.path;
      };

      tailscale = {
        enable = true;
        openFirewall = true;
        authKeyFile = config.sops.secrets.tailscale_auth_key.path;
        hostname = "portal";
        namespace = "orchard";
      };

      nginx = {
        enable = true;
        fqdn = "portal.orchard.computer";
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
                extraConfig = ''
                  allow 10.0.0.0/8;
                  allow 100.64.0.0/16;
                  deny all;
                '';
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
                "http://${nodes.htpc.config.orchard.services.tailscale.fqdn}:${
                  toString nodes.htpc.config.orchard.services.overseerr.port
                }";
              proxyWebsockets = true;
            };
          };

          "radarr.orchard.computer" = {
            http2 = true;

            addSSL = true;
            enableACME = true;

            locations."/" = {
              proxyPass =
                "http://${nodes.htpc.config.orchard.services.tailscale.fqdn}:${
                  toString nodes.htpc.config.orchard.services.radarr.port
                }";
              proxyWebsockets = true;
            };
          };

          "sonarr.orchard.computer" = {
            http2 = true;

            addSSL = true;
            enableACME = true;

            locations."/" = {
              proxyPass =
                "http://${nodes.htpc.config.orchard.services.tailscale.fqdn}:${
                  toString nodes.htpc.config.orchard.services.sonarr.port
                }";
              proxyWebsockets = true;
            };
          };

          "nzbget.orchard.computer" = {
            http2 = true;

            addSSL = true;
            enableACME = true;

            locations."/" = {
              proxyPass =
                "http://${nodes.htpc.config.orchard.services.tailscale.fqdn}:${
                  toString nodes.htpc.config.orchard.services.nzbget.port
                }";
              proxyWebsockets = true;
            };
          };

          "prowlarr.orchard.computer" = {
            http2 = true;

            addSSL = true;
            enableACME = true;

            locations."/" = {
              proxyPass =
                "http://${nodes.htpc.config.orchard.services.tailscale.fqdn}:${
                  toString nodes.htpc.config.orchard.services.prowlarr.port
                }";
              proxyWebsockets = true;
            };
          };

          "tautulli.orchard.computer" = {
            http2 = true;

            addSSL = true;
            enableACME = true;

            locations."/" = {
              proxyPass =
                "http://${nodes.htpc.config.orchard.services.tailscale.fqdn}:${
                  toString nodes.htpc.config.orchard.services.tautulli.port
                }";
              proxyWebsockets = true;
            };
          };

          "sabnzbd.orchard.computer" = {
            http2 = true;

            addSSL = true;
            enableACME = true;

            extraConfig = ''
              client_max_body_size 100M;
            '';

            locations."/" = {
              proxyPass =
                "http://${nodes.htpc.config.orchard.services.tailscale.fqdn}:${
                  toString nodes.htpc.config.orchard.services.sabnzbd.port
                }";
              proxyWebsockets = true;
            };
          };

          "jellyfin.orchard.computer" = {
            http2 = true;

            forceSSL = true;
            enableACME = true;

            locations."/" = {
              proxyPass =
                "http://${nodes.htpc.config.orchard.services.tailscale.fqdn}:${
                  toString nodes.htpc.config.orchard.services.jellyfin.port
                }";
              proxyWebsockets = true;
              extraConfig = ''
                proxy_buffering off;
              '';
            };
          };

          "smokeping.orchard.computer" = {
            http2 = true;
            forceSSL = true;
            enableACME = true;
            locations = let
              proxyPassBase =
                "http://${nodes.errata.config.orchard.services.tailscale.fqdn}:${
                  toString nodes.errata.config.orchard.services.smokeping.port
                }";
            in {
              "/" = { proxyPass = "${proxyPassBase}/smokeping.fcgi"; };
              "/cache" = { proxyPass = "${proxyPassBase}/cache"; };
              "/cropper" = { proxyPass = "${proxyPassBase}/cropper"; };
            };
          };

          "plex.orchard.computer" = {
            http2 = true;

            addSSL = true;
            enableACME = true;

            extraConfig = ''
              send_timeout 100m;
              ssl_stapling on;
              ssl_stapling_verify on;
              ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
              ssl_prefer_server_ciphers on;
              ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:ECDHE-RSA-DES-CBC3-SHA:ECDHE-ECDSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA';
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
              proxy_set_header Host $server_addr;
              proxy_set_header Referer $server_addr;
              proxy_set_header Origin $server_addr;
              gzip on;
              gzip_vary on;
              gzip_min_length 1000;
              gzip_proxied any;
              gzip_types text/plain text/css text/xml application/xml text/javascript application/x-javascript image/svg+xml;
              gzip_disable "MSIE [1-6]\.";
              client_max_body_size 100M;
              proxy_set_header X-Plex-Client-Identifier $http_x_plex_client_identifier;
              proxy_set_header X-Plex-Device $http_x_plex_device;
              proxy_set_header X-Plex-Device-Name $http_x_plex_device_name;
              proxy_set_header X-Plex-Platform $http_x_plex_platform;
              proxy_set_header X-Plex-Platform-Version $http_x_plex_platform_version;
              proxy_set_header X-Plex-Product $http_x_plex_product;
              proxy_set_header X-Plex-Token $http_x_plex_token;
              proxy_set_header X-Plex-Version $http_x_plex_version;
              proxy_set_header X-Plex-Nocache $http_x_plex_nocache;
              proxy_set_header X-Plex-Provides $http_x_plex_provides;
              proxy_set_header X-Plex-Device-Vendor $http_x_plex_device_vendor;
              proxy_set_header X-Plex-Model $http_x_plex_model;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection "upgrade";
              proxy_http_version 1.1;
              proxy_redirect off;
              proxy_buffering off;
            '';

            locations."/" = {
              proxyPass =
                "http://${nodes.htpc.config.orchard.services.tailscale.fqdn}:${
                  toString nodes.htpc.config.orchard.services.plex.port
                }";
              proxyWebsockets = true;
            };
          };
        };
      };

      promtail = {
        enable = true;
        host = "portal";
        lokiServerConfiguration = {
          host = nodes.monitor.config.orchard.services.loki.host;
          port = nodes.monitor.config.orchard.services.loki.port;
        };
      };

      prometheus-node-exporter = {
        enable = true;
        host = "portal.orchard.computer";
        openFirewall = true;
      };

      prometheus-nginx-exporter = {
        enable = true;
        scrapeUri = "http://portal.orchard.computer/stub_status";
        openFirewall = true;
      };

      restic = {
        enable = true;
        backupName = "portal";
        paths = [ "/var/lib" ];
        passwordFile = config.sops.secrets.backup_password.path;
        s3 = {
          bucketName = resources.s3Buckets.portal-backups-bucket.name;
          credentialsFile = config.sops.secrets.aws_credentials.path;
        };
      };
    };
  };
}
