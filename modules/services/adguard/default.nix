{ config, pkgs, lib, ... }:

with lib;

let cfg = config.orchard.services.adguard;
in {
  options.orchard.services.adguard = {
    enable = mkEnableOption "Enable AdGuard Home";
    port = mkOption {
      type = types.port;
      default = 3000;
    };
    openFirewall = mkOption {
      type = types.bool;
      default = false;
    };
    addr = mkOption {
      type = types.str;
      default = "0.0.0.0";
    };
    nginx = mkOption {
      type = types.submodule {
        options = {
          enable = mkEnableOption "Enable Nginx for AdGuard";
          host = mkOption { type = types.str; };
          port = mkOption { type = types.port; };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    services.adguardhome = {
      inherit (cfg) enable port;

      host = cfg.addr;
    };

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ 53 ];
      allowedUDPPorts = [ 53 ];
    };

    services.nginx = mkIf cfg.nginx.enable {
      virtualHosts.${cfg.nginx.host} = {
        http2 = true;
        addSSL = true;
        enableACME = true;

        locations."/" = {
          proxyPass = "http://${cfg.addr}:${toString cfg.port}";
        };
      };
    };
  };
}
