{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.flood;
in {
  options.orchard.services.flood = {
    enable = mkEnableOption "Enable Flood torrent client";
    port = mkOption {
      type = types.port;
      default = 3000;
    };
    openFirewall = mkOption {
      type = types.bool;
      default = false;
    };
    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/flood";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.flood = {
      image = "jesec/flood";
      ports = [ "${toString cfg.port}:3000" ];
      volumes = [ "${cfg.dataDir}:/data" ];
    };

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
      allowedUDPPorts = [ cfg.port ];
    };
  };
}
