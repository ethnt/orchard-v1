{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.orchard.services.qbittorrent;
  bindMountOpts = { name, ... }: {

    options = {
      mountPoint = mkOption {
        example = "/mnt/usb";
        type = types.str;
        description = "Mount point on the container file system.";
      };
      hostPath = mkOption {
        default = null;
        example = "/home/alice";
        type = types.nullOr types.str;
        description = "Location of the host path to be mounted.";
      };
      isReadOnly = mkOption {
        default = true;
        type = types.bool;
        description =
          "Determine whether the mounted path will be accessed in read-only mode.";
      };
    };

    config = { mountPoint = mkDefault name; };

  };
in {
  options.orchard.services.qbittorrent = {
    enable = mkEnableOption "Enable qbittorrent torrent client";
    port = mkOption {
      type = types.port;
      default = 3591;
    };
    openFirewall = mkOption {
      type = types.bool;
      default = false;
    };
    user = mkOption {
      type = types.str;
      default = "qbittorrent";
    };
    group = mkOption {
      type = types.str;
      default = "qbittorrent";
    };
    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/qbittorrent";
    };
    mediaDir = mkOption {
      type = types.str;
      default = "/tmp";
    };

    container = mkOption {
      type = types.submodule {
        options = {
          bridgeInterface = mkOption {
            type = types.str;
            default = "br0";
          };

          macAddress = mkOption {
            type = types.nullOr (types.str);
            default = null;
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.qbittorrent-mountpoints = {
      serviceConfig.Type = "oneshot";

      wantedBy = [ "container@qbittorrent.service" ];

      script = ''
        mkdir -p ${cfg.dataDir}
        chmod -R 777 ${cfg.dataDir}

        mkdir -p ${cfg.mediaDir}
        chmod -R 0700 ${cfg.mediaDir}
      '';
    };

    containers.qbittorrent = {
      autoStart = true;
      # TODO: Make this ephemeral
      ephemeral = false;
      extraFlags = [ "-U" ];

      privateNetwork = true;
      hostBridge = cfg.container.bridgeInterface;
      forwardPorts = [
        {
          protocol = "tcp";
          hostPort = cfg.port;
          containerPort = cfg.port;
        }
        {
          protocol = "udp";
          hostPort = cfg.port;
          containerPort = cfg.port;
        }
      ];

      bindMounts = mkMerge [{
        "${cfg.dataDir}" = {
          hostPath = cfg.dataDir;
          isReadOnly = false;
        };

        "${cfg.mediaDir}" = {
          hostPath = cfg.mediaDir;
          isReadOnly = false;
        };
      }
      # cfg.container.extraBindMounts
        ];

      config = { config, lib, pkgs, ... }: {
        boot.isContainer = true;

        networking = {
          hostName = "qbittorrent";
          interfaces = {
            "eth0" = {
              useDHCP = true;
              macAddress = cfg.container.macAddress;
            };
          };

          useHostResolvConf = false;
        };

        services.resolved.enable = true;

        systemd.tmpfiles.rules =
          [ "d '${cfg.dataDir}' 0700 ${cfg.user} ${cfg.group} - -" ];

        systemd.services.qbittorrent = {
          description = "qBittorrent";
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];

          serviceConfig = {
            Type = "simple";
            User = cfg.user;
            Group = cfg.group;
            ExecStart =
              "${pkgs.qbittorrent-nox}/bin/qbittorrent-nox --profile=${cfg.dataDir} --webui-port=${
                toString cfg.port
              }";
            Restart = "on-failure";
          };
        };

        networking.firewall =
          mkIf cfg.openFirewall { allowedTCPPorts = [ cfg.port ]; };

        users.users = mkIf (cfg.user == "qbittorrent") {
          qbittorrent = {
            group = cfg.group;
            home = cfg.dataDir;
            uid = 333;
          };
        };

        users.groups =
          mkIf (cfg.group == "qbittorrent") { qbittorrent.gid = 333; };
      };
    };
  };
}
