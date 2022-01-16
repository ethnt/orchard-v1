{ config, pkgs, resources, nodes, ... }: {
  deployment = { targetHost = "100.101.26.126"; };

  imports = [ ./hardware-configuration.nix ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  orchard = {
    services = {
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
