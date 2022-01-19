{ config, pkgs, resources, nodes, ... }: {
  deployment = { targetHost = "100.101.26.126"; };

  sops.secrets = { innernet_private_key = { sopsFile = ./secrets.yaml; }; };

  networking.publicIPv4 = "68.173.239.21";

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

      nginx = {
        enable = true;
        acme.email = "ethan.turkeltaub+orchard-computer@hey.com";
      };

      innernet = {
        server.orchard = {
          enable = true;
          settings = {
            openFirewall = true;
            cidr = "192.168.104.0/22";
            listenPort = 51820;
            privateKeyFile = config.sops.secrets.innernet_private_key.path;
            publicKey = "Wb2qIzK5Ra94p1IQmBgtMiP47wFvx15iSaWYFT4UMGM=";
            internalEndpoint = "192.168.104.1:${
                toString
                config.orchard.services.innernet.server.orchard.settings.listenPort
              }";
            externalEndpoint = "${config.networking.publicIPv4}:${
                toString
                config.orchard.services.innernet.server.orchard.settings.listenPort
              }";
            cidrs = {
              internal = {
                cidr = "192.168.104.64/26";
                parent = "orchard";
              };
            };
            peers = {
              htpc = {
                ip = "192.168.104.65";
                cidr = "internal";
                publicKey = "17Zh1Yp1EPSIOY5WiOzexWAIW8ScO6ZKpo1UJM/wwV4=";
              };
              builder = {
                ip = "192.168.104.66";
                cidr = "internal";
                publicKey = "bIZ9lorQgfFDac3Hi2E5ZPcC5ujlvZo/6yhJI7rvHwE=";
              };
            };
          };
        };
      };
    };
  };
}
