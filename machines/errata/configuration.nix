{ config, pkgs, resources, nodes, ... }: {
  deployment = { targetHost = "192.168.1.45"; };

  imports = [ ../../profiles/virtualized ./hardware-configuration.nix ];

  sops = {
    secrets = {
      nebula_host_key = { sopsFile = ./secrets.yaml; };
      nebula_host_cert = { sopsFile = ./secrets.yaml; };
      tailscale_auth_key = { sopsFile = ./secrets.yaml; };
    };
  };

  networking.privateIPv4 = "192.168.1.45";

  orchard = {
    services = {
      tailscale = {
        enable = true;
        openFirewall = true;
        authKeyFile = config.sops.secrets.tailscale_auth_key.path;
        hostname = "errata";
        namespace = "orchard";
      };

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
        enable = false;
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

      smokeping = {
        enable = true;
        openFirewall = true;
        externalHost = config.networking.privateIPv4;
        targetConfig = ''
          + Local
          menu = Local
          title = Local Network

          ++ Localhost
          menu = Localhost
          title = Localhost
          host = localhost

          ++ Router
          menu = Router
          title = Router
          host = 192.168.1.1

          + Internet
          menu = Internet
          title = Internet

          ++ Google
          menu = Google
          title = google.com
          host = google.com

          + DNS
          menu = DNS
          title = DNS

          ++ GoogleDNS
          menu = Google DNS
          title = Google DNS
          host = 8.8.8.8

          ++ CloudflareDNS
          menu = Cloudflare DNS
          title = Cloudflare DNS
          host = 1.1.1.1

          + Global
          menu = Global
          title = Global Connectivity

          ++ Germany

          menu = Germany
          title = Germany

          +++ TelefonicaDE

          menu = Telefonica DE
          title = Telefonica DE
          host = www.telefonica.de

          ++ Switzerland

          menu = Switzerland
          title = Switzerland

          +++ CernIXP

          menu = CernIXP
          title = Cern Internet eXchange Point
          host = cixp.web.cern.ch

          ++ UK
          menu = United Kingdom
          title = United Kingdom

          +++ CambridgeUni
          menu = Cambridge
          title = Cambridge
          host = cam.ac.uk

          +++ UCL
          menu = UCL
          title = UCL
          host = www.ucl.ac.uk

          ++ USA
          menu = United States
          title = United States

          +++ MIT
          menu = MIT
          title = Massachusetts Institute of Technology Webserver
          host = web.mit.edu

          +++ UCB
          menu = U. C. Berkeley
          title = U. C. Berkeley
          host = www.berkeley.edu

          +++ UCSD
          menu = U. C. San Diego
          title = U. C. San Diego
          host = ucsd.edu

          +++ UMN
          menu =  University of Minnesota
          title = University of Minnesota
          host = twin-cities.umn.edu

          +++ OSUOSL
          menu = Oregon State University Open Source Lab
          title = Oregon State University Open Source Lab
          host = osuosl.org
        '';
      };
    };
  };
}
