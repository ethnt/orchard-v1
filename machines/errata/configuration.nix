{ config, pkgs, resources, nodes, ... }: {
  deployment = { targetHost = "192.168.1.45"; };

  imports = [ ../../profiles/virtualized ./hardware-configuration.nix ];

  sops = {
    secrets = {
      nebula_host_key = { sopsFile = ./secrets.yaml; };
      nebula_host_cert = { sopsFile = ./secrets.yaml; };
    };
  };

  networking.privateIPv4 = "192.168.1.45";

  orchard = {
    services = {
      nebula = {
        enable = true;
        network = {
          lighthouses = [ "10.10.10.1" ];
          staticHostMap = {
            "10.10.10.1" =
              [ "${nodes.gateway.config.deployment.targetHost}:4242" ];
          };
        };
        host = {
          addr = "10.10.10.3";
          keyPath = config.sops.secrets.nebula_host_key.path;
          certPath = config.sops.secrets.nebula_host_cert.path;
        };
      };

      docker.enable = true;

      unifi = {
        enable = true;
        openFirewall = true;
      };

      apcupsd = {
        enable = true;
        configText = ''
          UPSCABLE usb
          UPSTYPE usb
          DEVICE
        '';
      };

      promtail = {
        enable = true;
        host = "errata";
        lokiServerConfiguration = {
          host = nodes.monitor.config.orchard.services.loki.host;
          port = nodes.monitor.config.orchard.services.loki.port;
        };
      };

      prometheus-node-exporter = {
        enable = true;
        host = "errata.orchard.computer";
        openFirewall = true;
      };

      prometheus-apcupsd-exporter = {
        enable = true;
        openFirewall = true;
      };

      prometheus-snmp-exporter = {
        enable = true;
        openFirewall = true;
        configurationFile = ./prometheus/snmp/snmp.yml;
      };

      prometheus-smokeping-exporter = {
        enable = true;
        openFirewall = true;
        hosts = [ "1.1.1.1" "8.8.8.8" "192.168.1.1" "127.0.0.1" ];
      };

      restic = {
        enable = true;
        backupName = "errata";
        paths = [ "/var/lib" ];
        passwordFile = config.sops.secrets.backup_password.path;
        s3 = {
          bucketName = resources.s3Buckets.errata-backups-bucket.name;
          credentialsFile = config.sops.secrets.aws_credentials.path;
        };
      };
    };
  };
}
