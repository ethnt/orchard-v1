{ config, pkgs, resources, nodes, ... }: {
  deployment = { targetHost = "192.168.1.11"; };

  imports = [ ./hardware-configuration.nix ];

  networking.publicIPv4 = "192.168.1.11";
  networking.privateIPv4 = "192.168.1.11";

  # sops.secrets = {
  #   nebula_ca_cert = { sopsFile = ../secrets.yaml; };
  #   nebula_host_key = { sopsFile = ./secrets.yaml; };
  #   nebula_host_cert = { sopsFile = ./secrets.yaml; };
  # };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  services.qemuGuest.enable = true;

  system.stateVersion = "21.11";

  orchard = {
    services = {
      # nebula = {
      #   enable = true;
      #   caCert = config.sops.secrets.nebula_ca_cert.path;
      #   hostKey = config.sops.secrets.nebula_host_key.path;
      #   hostCert = config.sops.secrets.nebula_host_cert.path;
      #   staticHostMap = {
      #     "10.11.12.1" =
      #       [ "${nodes.bastion.config.networking.publicIPv4}:4242" ];
      #   };
      #   lighthouses = [ "10.11.12.1" ];
      # };

      prometheus-exporter = {
        enable = true;
        host = "unifi";
        node = {
          enable = true;
          openFirewall = true;
        };
      };

      unifi = {
        enable = true;
        openFirewall = true;
      };

      promtail = {
        enable = true;
        host = "unifi";
        lokiServerConfiguration = {
          host = nodes.monitor.config.networking.privateIPv4;
          port = nodes.monitor.config.orchard.services.loki.port;
        };
      };
    };
  };
}
