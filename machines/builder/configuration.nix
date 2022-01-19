{ config, pkgs, resources, nodes, ... }: {
  deployment = { targetHost = "192.168.1.219"; };

  imports = [ ./hardware-configuration.nix ];

  sops.secrets = { innernet_private_key = { sopsFile = ./secrets.yaml; }; };

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
              address = "192.168.104.66/22";
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
        host = "builder.orchard.computer";
        node = {
          enable = true;
          openFirewall = true;
        };
      };

      promtail = {
        enable = false;
        host = "builder.orchard.computer";
        lokiServerConfiguration = {
          host = nodes.monitor.config.orchard.services.loki.host;
          port = nodes.monitor.config.orchard.services.loki.port;
        };
      };

      remote-builder = {
        enable = false;
        emulatedSystems = [ "aarch64-linux" ];
        buildUserKeyFile = ./keys/builder.pub;
      };
    };
  };
}
