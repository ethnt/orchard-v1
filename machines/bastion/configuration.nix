{ config, pkgs, resources, nodes, ... }: {
  deployment = { targetHost = "100.101.26.126"; };

  imports = [ ./hardware-configuration.nix ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  sops.secrets = {
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

      prometheus-exporter = {
        enable = true;
        host = "bastion.orchard.computer";
        node = {
          enable = true;
          openFirewall = true;
        };
      };

      promtail = {
        enable = true;
        host = "bastion.orchard.computer";
        lokiServerConfiguration = {
          host = nodes.monitor.config.orchard.services.loki.host;
          port = nodes.monitor.config.orchard.services.loki.port;
        };
      };
    };
  };
}
