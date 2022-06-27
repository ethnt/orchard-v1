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
        hostname = "gateway";
        namespace = "orchard";
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
