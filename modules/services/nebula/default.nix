{ config, pkgs, lib }:

with lib;

let
  cfg = config.orchard.services.nebula;
  port = 4242;
in {
  options.orchard.services.nebula = {
    enable = mkEnableOption "Enable networking with Nebula";
    port = mkOption {
      type = types.port;
      default = 4242;
    };
    isLighthouse = mkOption {
      type = types.boolean;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    deployment.keys = {
      nebula-crt = { keyFile = ../modules/services/nebula/keys/ca.crt; };
    };

    services.nebula.networks.orchard = {
      inherit (cfg) enable isLighthouse;
      ca = deployment.keys.nebula-crt;
    };

    networking.firewall.allowedUDPPorts = [ cfg.port ];
  };
}
