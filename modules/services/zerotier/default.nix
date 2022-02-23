{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.zerotier;
in {
  options.orchard.services.zerotier = {
    enable = mkEnableOption "Enable ZeroTier VPN";
    networkId = mkOption { type = types.str; };
    addr = mkOption { type = types.str; };
  };

  config = mkIf cfg.enable {
    services.zerotierone = {
      enable = true;
      joinNetworks = [ cfg.networkId ];
    };
  };
}
