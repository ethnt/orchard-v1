{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.pve-exporter;
in {
  options.orchard.services.pve-exporter = {
    enable = mkEnableOption "Enable the PVE Exporter";

    port = mkOption {
      type = types.port;
      default = 9221;
    };

    configFile = mkOption { type = types.str; };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.pve-exporter = {
      image = "prompve/prometheus-pve-exporter";
      ports = [ "0.0.0.0:${toString cfg.port}:9221" ];
      volumes = [ "${cfg.configFile}:/etc/pve.yml" ];
    };

    systemd.services.docker-pve-exporter = {
      serviceConfig.SupplementaryGroups = [ config.users.groups.keys.name ];
    };

    networking.firewall =
      mkIf cfg.openFirewall { allowedTCPPorts = [ cfg.port ]; };
  };
}
