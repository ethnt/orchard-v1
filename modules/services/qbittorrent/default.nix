{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.qbittorrent;
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
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0700 ${cfg.user} ${cfg.group} - -"
    ];

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

    users.groups = mkIf (cfg.group == "qbittorrent") {
      qbittorrent.gid = 333;
    };
  };
}
