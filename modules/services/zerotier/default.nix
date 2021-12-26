{ config, pkgs, lib }:

with lib;

let cfg = config.orchard.services.zerotier;
in {
  options.orchard.services.zerotier = {
    enable = mkEnableOption "Enable networking with ZeroTier";
    joinNetworks = mkOption {
      type = types.listOf types.string;
      default = [ ];
    };
    openFirewall = mkOption {
      type = types.boolean;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    services.zerotier = { inherit (cfg) enable joinNetworks; };

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ 9993 ];
      allowedUDPPorts = [ 9993 ];
    };
  };
}
