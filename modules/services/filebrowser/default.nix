{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.filebrowser;
in {
  options.orchard.services.filebrowser = {
    enable = mkEnableOption "Enable filebrowser";
    port = mkOption {
      type = types.port;
      default = 8010;
    };
    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/filebrowser";
    };
    srvDir = mkOption {
      type = types.str;
      default = "/var/www";
    };
    openFirewall = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    systemd.services."filebrowser-files" = {
      serviceConfig.Type = "oneshot";

      wantedBy = [ "docker-filebrowser.service" ];

      script = let
        # TODO: Make this configurable
        configFile = pkgs.writeText "filebrowser.json" ''
          {
            "port": 80,
            "baseURL": "",
            "address": "",
            "log": "stdout",
            "database": "/database/filebrowser.db",
            "root": "/srv"
          }
        '';
      in ''
        mkdir -p ${cfg.dataDir}
        touch ${cfg.dataDir}/database.db
        ln -s ${configFile} ${cfg.dataDir}/filebrowser.json
      '';
    };

    # TODO: Make a package for this
    virtualisation.oci-containers.containers.filebrowser = {
      image = "filebrowser/filebrowser";
      ports = [ "${toString cfg.port}:80" ];
      volumes = [
        "${cfg.srvDir}:/srv"
        "${cfg.dataDir}/database.db:/database.db"
        "${cfg.dataDir}/filebrowser.json:/.filebrowser.json"
      ];
    };

    networking.firewall =
      mkIf cfg.openFirewall { allowedTCPPorts = [ cfg.port ]; };
  };
}
