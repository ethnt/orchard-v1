{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.radarr;
in {
  options.orchard.services.radarr = {
    enable = mkEnableOption "Enable Radarr";
    host = mkOption {
      type = types.str;
      default = "0.0.0.0";
    };
    port = mkOption {
      type = types.port;
      default = 7878;
    };
    openFirewall = mkOption {
      type = types.bool;
      default = false;
    };
    user = mkOption {
      type = types.str;
      default = "radarr";
    };
    group = mkOption {
      type = types.str;
      default = "radarr";
    };
    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/radarr/.config/NzbDrone";
    };
  };

  config = mkIf cfg.enable {
    services.radarr = { inherit (cfg) enable openFirewall user group dataDir; };
  };
}
