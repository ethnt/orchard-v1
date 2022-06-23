{ config, pkgs, resources, nodes, ... }: {
  deployment = { targetHost = "192.168.1.43"; };

  imports = [ ../../profiles/virtualized ./hardware-configuration.nix ];

  sops = {
    secrets = {
      nebula_host_key = { sopsFile = ./secrets.yaml; };
      nebula_host_cert = { sopsFile = ./secrets.yaml; };
      tailscale_auth_key = { sopsFile = ./secrets.yaml; };
    };
  };

  # TODO: Make this not manual
  networking.publicIPv4 = "67.244.78.4";
  networking.privateIPv4 = "192.168.1.43";

  orchard = {
    services = {
      tailscale = {
        enable = true;
        openFirewall = true;
        authKeyFile = config.sops.secrets.tailscale_auth_key.path;
      };

      fail2ban = {
        enable = true;
        allowlist = [
          "127.0.0.0/8"
          "10.0.0.0/8"
          "100.0.0.0/8"
          "172.16.0.0/12"
          "192.168.0.0/16"
          "8.8.8.8"
        ];
      };

      nebula = {
        enable = true;
        host = {
          addr = "10.10.10.1";
          isLighthouse = true;
          keyPath = config.sops.secrets.nebula_host_key.path;
          certPath = config.sops.secrets.nebula_host_cert.path;
        };
      };

      nginx = {
        enable = true;
        acme = { email = "admin@orchard.computer"; };
        virtualHosts = {
          "gateway.orchard.computer" = {
            locations."/stub_status" = {
              extraConfig = ''
                stub_status;
              '';
            };
          };

          "metrics.satan.orchard.computer" = {
            locations."/" = { proxyPass = "http://192.168.1.1:9002"; };
          };

          # "pve.orchard.computer" = {
          #   http2 = true;

          #   addSSL = true;
          #   enableACME = true;

          #   locations."/" = { proxyPass = "http://192.168.1.42:8006"; };
          # };

          "sonarr.orchard.computer" = {
            http2 = true;

            addSSL = true;
            enableACME = true;

            locations."/" = {
              proxyPass =
                "http://${nodes.htpc.config.orchard.services.nebula.host.addr}:${
                  toString nodes.htpc.config.orchard.services.sonarr.port
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
                "http://${nodes.htpc.config.orchard.services.nebula.host.addr}:${
                  toString nodes.htpc.config.orchard.services.radarr.port
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
                "http://${nodes.htpc.config.orchard.services.nebula.host.addr}:${
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
                "http://${nodes.htpc.config.orchard.services.nebula.host.addr}:${
                  toString nodes.htpc.config.orchard.services.prowlarr.port
                }";
              proxyWebsockets = true;
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

          "tautulli.orchard.computer" = {
            http2 = true;

            addSSL = true;
            enableACME = true;

            locations."/" = {
              proxyPass =
                "http://${nodes.htpc.config.orchard.services.nebula.host.addr}:${
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
                "http://${nodes.htpc.config.orchard.services.nebula.host.addr}:${
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
                "http://${nodes.htpc.config.orchard.services.nebula.host.addr}:${
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
                "http://${nodes.errata.config.orchard.services.nebula.host.addr}:${
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
                "http://${nodes.htpc.config.orchard.services.nebula.host.addr}:${
                  toString nodes.htpc.config.orchard.services.plex.port
                }";
              proxyWebsockets = true;
            };
          };
        };
      };

      promtail = {
        enable = true;
        host = "gateway";
        lokiServerConfiguration = {
          host = nodes.monitor.config.orchard.services.loki.host;
          port = nodes.monitor.config.orchard.services.loki.port;
        };
      };

      prometheus-node-exporter = {
        enable = true;
        host = "gateway.orchard.computer";
        openFirewall = true;
      };

      prometheus-nginx-exporter = {
        enable = true;
        scrapeUri = "http://gateway.orchard.computer/stub_status";
        openFirewall = true;
      };

      restic = {
        enable = true;
        backupName = "gateway";
        paths = [ "/var/lib" ];
        passwordFile = config.sops.secrets.backup_password.path;
        s3 = {
          bucketName = resources.s3Buckets.gateway-backups-bucket.name;
          credentialsFile = config.sops.secrets.aws_credentials.path;
        };
      };
    };
  };
}
