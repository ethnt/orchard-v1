{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.prometheus-smokeping-exporter;
in {
  options.orchard.services.prometheus-smokeping-exporter = {
    enable = mkEnableOption "Enable Smokeping";
    host = mkOption { type = types.str; };
    port = mkOption {
      type = types.port;
      default = 9374;
    };
    hosts = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
    configurationFile = mkOption { type = types.path; };
    openFirewall = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    services.prometheus.exporters.smokeping = {
      inherit (cfg) enable port openFirewall hosts;
    };
  };
}
