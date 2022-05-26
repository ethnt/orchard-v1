{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.smokeping;
in {
  options.orchard.services.smokeping = {
    enable = mkEnableOption "Enable Smokeping";
    host = mkOption {
      type = types.str;
      default = "0.0.0.0";
    };
    externalHost = mkOption { type = types.str; };
    port = mkOption {
      type = types.port;
      default = 8081;
    };
    targetConfig = mkOption {
      type = types.lines;
      default = "";
    };
    openFirewall = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    services.smokeping = {
      inherit (cfg) enable host;

      hostName = cfg.externalHost;
      owner = "orchard";
      webService = true;
      targetConfig = ''
        probe = FPing

        menu = Top
        title = Network Latency
        remark = Satan/Orchard network latency

        ${cfg.targetConfig}
      '';
    };

    networking.firewall =
      mkIf cfg.openFirewall { allowedTCPPorts = [ cfg.port ]; };
  };
}
