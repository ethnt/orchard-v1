{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.sonarr;
in {
  options.orchard.services.sonarr = {
    enable = mkEnableOption "Enable Sonarr";
    host = mkOption {
      type = types.str;
      default = "0.0.0.0";
    };
    port = mkOption {
      type = types.port;
      default = 8989;
    };
    openFirewall = mkOption {
      type = types.bool;
      default = false;
    };
    user = mkOption {
      type = types.str;
      default = "sonarr";
    };
    group = mkOption {
      type = types.str;
      default = "sonarr";
    };
    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/sonarr/.config/NzbDrone";
    };
  };

  config = mkIf cfg.enable {
    services.sonarr = { inherit (cfg) enable openFirewall user group dataDir; };
  };
}
