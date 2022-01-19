{ config, lib, pkgs, nodes, ...}:

with lib;

let cfg = config.orchard.services.sonarr;
in {
  options.orchard.services.sonarr = {
    enable = mkEnableOption "Enable Sonarr";
    addr = mkOption {
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
    nginx = mkOption {
      type = types.submodule {
        options = {
          enable = mkEnableOption "Enable Nginx for Sonarr";
          host = mkOption { type = types.str; };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    services.sonarr = {
      inherit (cfg) enable openFirewall;
    };
  };
}
