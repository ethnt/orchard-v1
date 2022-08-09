{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.xteve;
in {
  options.orchard.services.xteve = {
    enable = mkEnableOption "Enable xTeVe";
    port = mkOption {
      type = types.port;
      default = 34400;
    };
    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/xteve";
    };
    openFirewall = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.xteve = {
      image = "alturismo/xteve";
      ports = [ "${toString cfg.port}:34400" ];
      environment = { TZ = "America/New_York"; };
      volumes = [
        "${cfg.dataDir}:/root/.xteve:rw"
        "${cfg.dataDir}/config:/config:rw"
        "/tmp/xteve:/tmp/xteve"
      ];
    };

    networking.firewall =
      mkIf cfg.openFirewall { allowedTCPPorts = [ cfg.port ]; };
  };
}
