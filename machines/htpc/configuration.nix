{ config, pkgs, resources, nodes, ... }: {
  deployment = { targetHost = "100.117.182.50"; };

  imports = [ ./hardware-configuration.nix ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  orchard = {
    services = {
      prometheus-exporter = {
        enable = false;
        host = "htpc.orchard.computer";
        node = {
          enable = true;
          openFirewall = true;
        };
      };

      promtail = {
        enable = false;
        host = "htpc.orchard.computer";
        lokiServerConfiguration = {
          host = nodes.monitor.config.orchard.services.loki.host;
          port = nodes.monitor.config.orchard.services.loki.port;
        };
      };

      sonarr = {
        enable = true;
        openFirewall = true;
      };
    };
  };
}
