{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.prowlarr;
in {
  options.orchard.services.prowlarr = {
    enable = mkEnableOption "Enable Prowlarr";
    port = mkOption {
      type = types.port;
      default = 9696;
    };
    openFirewall = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    services.prowlarr = { inherit (cfg) enable openFirewall; };
  };
}
