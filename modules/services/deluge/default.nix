{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.deluge;
in {
  options.orchard.services.deluge = {
    enable = mkEnableOption "Enable Deluge";
    port = mkOption {
      type = types.port;
      default = 8112;
    };
    openFirewall = mkOption {
      type = types.bool;
      default = false;
    };
    user = mkOption {
      type = types.str;
      default = "deluge";
    };
    group = mkOption {
      type = types.str;
      default = "deluge";
    };
    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/deluge";
    };
    # container = mkOption {
    #   type = types.submodule {
    #     options = {
    #       bridgeInterface = mkOption {
    #         type = types.str;
    #         default = "br0";
    #       };

    #       macAddress = mkOption {
    #         type = types.nullOr (types.str);
    #         default = null;
    #       };
    #     };
    #   };
    # };
  };

  config = mkIf cfg.enable {
    # We need to create the mountpoints and also make the permissions wide open so the container can access them
    systemd.services.deluge-mountpoints = {
      serviceConfig.Type = "oneshot";

      wantedBy = [ "container@deluge.service" ];

      script = ''
        mkdir -p ${cfg.dataDir}
        ${pkgs.acl}/bin/setfacl -m o:rwx ${cfg.dataDir}
      '';
    };

    containers.deluge = let containerDataDir = "/srv/deluge";
    in {
      autoStart = true;
      ephemeral = true;
      extraFlags = [ "-U" ];

      privateNetwork = true;
      hostBridge = "br0";

      bindMounts = {
        "data" = {
          hostPath = cfg.dataDir;
          mountPoint = containerDataDir;
          isReadOnly = false;
        };
      };

      forwardPorts = [
        {
          protocol = "tcp";
          hostPort = cfg.port;
          containerPort = cfg.port;
        }
        {
          protocol = "udp";
          hostPort = 56311;
          containerPort = 56311;
        }
      ];

      config = { config, lib, pkgs, ... }: {
        boot.isContainer = true;

        networking = {
          hostName = "deluge";
          interfaces = {
            "eth0" = {
              useDHCP = true;
              macAddress = "8e:08:53:57:bb:9f";
            };
          };
          useHostResolvConf = false;
        };

        services.resolved.enable = true;

        services.deluge = {
          inherit (cfg) enable user group;

          dataDir = "/srv/deluge";

          web = {
            enable = true;
            port = cfg.port;
          };
        };

        networking.firewall = mkIf cfg.openFirewall {
          allowedTCPPorts = [ cfg.port ];
          allowedUDPPorts = [ cfg.port 56311 ];
        };
      };
    };
  };
}
