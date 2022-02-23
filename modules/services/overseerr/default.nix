{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.overseerr;
in {
  options.orchard.services.overseerr = {
    enable = mkEnableOption "Enable Overseerr";
    port = mkOption {
      type = types.port;
      default = 5055;
    };
    openFirewall = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.overseerr = {
      image = "sctx/overseerr";
      environment = {
        LOG_LEVEL = "debug";
        TZ = "America/New_York";
      };
      ports = [ "${toString cfg.port}:5055" ];
      volumes = [ "/var/lib/overseerr:/app/config" ];
    };

    networking.firewall =
      mkIf cfg.openFirewall { allowedTCPPorts = [ cfg.port ]; };
  };
}
