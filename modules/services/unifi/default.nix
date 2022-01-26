{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.unifi;
in {
  options.orchard.services.unifi = {
    enable = mkEnableOption "Enable the Unifi controller";
    openFirewall = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    services.unifi = {
      enable = true;
      openPorts = cfg.openFirewall;
      unifiPackage = pkgs.unifi;
    };

    # The service doesn't do this for us
    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ 8443 ];
      allowedUDPPorts = [ 8443 ];
    };
  };
}
