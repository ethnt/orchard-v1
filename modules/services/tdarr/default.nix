{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.tdarr;
in {
  options.orchard.services.tdarr = {
    enable = mkEnableOption "Enable Tdarr transcoding";

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/tdarr";
    };

    mediaDir = mkOption {
      type = types.str;
      default = "/media";
    };

    transcodeCacheDir = mkOption {
      type = types.str;
      default = "/tmp";
    };

    # server = mkOption {
    #   type = types.submodule {
    #     options = {
    #       host = mkOption {
    #         type = types.str;
    #         default = "0.0.0.0";
    #       };
    #       port = mkOption {
    #         type = types.port;
    #         default = 8266;
    #       };
    #     };
    #   };
    # };

    # web = mkOption {
    #   type = types.submodule {
    #     options = {
    #       port = mkOption {
    #         type = types.port;
    #         default = 8265;
    #       };
    #     };
    #   };
    # };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.tdarr-server = {
      image = "ghcr.io/haveagitgat/tdarr";
      volumes = [
        "${cfg.dataDir}/server:/app/server"
        "${cfg.dataDir}/configs:/app/configs"
        "${cfg.dataDir}/logs:/app/logs"
        "${cfg.mediaDir}:/media"
        "${cfg.transcodeCacheDir}:/temp"
      ];
      environment = {
        serverIP = "192.168.1.44";
        serverPort = "8266";
        webUIPort = "8265";
        TZ = "America/New_York";
        PUID = "1000";
        PGID = "1000";
      };
      ports = [ "8265:8265" "8266:8266" ];
      extraOptions = [
        "--network=bridge"
        # "--gpus=all" "--device=/dev/dri:/dev/dri"
      ];
    };

    virtualisation.oci-containers.containers.tdarr-node = {
      image = "ghcr.io/haveagitgat/tdarr_node";
      volumes = [
        "${cfg.dataDir}/configs:/app/configs"
        "${cfg.dataDir}/logs:/app/logs"
        "${cfg.mediaDir}:/media"
        "${cfg.transcodeCacheDir}:/temp"
      ];
      environment = {
        serverIP = "192.168.1.44";
        serverPort = "8266";
        nodeID = "tdarr-node";
        nodeIP = "192.168.1.44";
        nodePort = "8267";
        TZ = "America/New_York";
        PUID = "1000";
        PGID = "1000";
      };
      ports = [ "8267:8267" ];
      extraOptions = [
        "--network=bridge"
        # "--gpus=all" "--device=/dev/dri:/dev/dri"
      ];
    };

    networking.firewall.allowedTCPPorts = [ 8265 8266 8267 ];
  };
}
