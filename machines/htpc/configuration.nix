{ config, pkgs, resources, nodes, ... }: {
  deployment = { targetHost = "100.117.182.50"; };

  sops.secrets = { innernet_private_key = { sopsFile = ./secrets.yaml; }; };

  imports = [ ./hardware-configuration.nix ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  orchard = {
    services = {
      innernet = {
        client.orchard = {
          enable = true;
          settings = {
            interface = {
              address = "192.168.104.65/22";
              privateKeyFile = config.sops.secrets.innernet_private_key.path;
            };
            server = {
              inherit (nodes.bastion.config.orchard.services.innernet.server.orchard.settings)
                publicKey externalEndpoint internalEndpoint;
            };
          };
        };
      };

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
    };
  };
}
