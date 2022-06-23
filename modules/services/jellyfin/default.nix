{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.jellyfin;
in {
  options.orchard.services.jellyfin = {
    enable = mkEnableOption "Enable Jellyfin";
    port = mkOption {
      type = types.port;
      default = 8096;
    };
    openFirewall = mkOption {
      type = types.bool;
      default = false;
    };
    user = mkOption {
      type = types.str;
      default = "jellyfin";
    };
    group = mkOption {
      type = types.str;
      default = "jellyfin";
    };
  };

  config = mkIf cfg.enable {
    services.jellyfin = {
      inherit (cfg) enable user group openFirewall;

      package = pkgs.jellyfin;
    };
  };
}
