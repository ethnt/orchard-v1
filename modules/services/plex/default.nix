{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.plex;
in {
  options.orchard.services.plex = {
    enable = mkEnableOption "Enable Plex";
    port = mkOption {
      type = types.port;
      default = 32400;
    };
    openFirewall = mkOption {
      type = types.bool;
      default = false;
    };
    user = mkOption {
      type = types.str;
      default = "plex";
    };
    group = mkOption {
      type = types.str;
      default = "plex";
    };
    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/plex";
    };
  };

  config = mkIf cfg.enable {
    services.plex = { inherit (cfg) enable user group openFirewall dataDir; };
  };
}
