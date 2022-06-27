{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.nginx;
in {
  options.orchard.services.nginx = {
    enable = mkEnableOption "Enable Nginx";
    acme = mkOption {
      type = types.submodule {
        options = { email = mkOption { type = types.str; }; };
      };
    };
    fqdn = mkOption { type = types.str; };
    virtualHosts = mkOption {
      type = types.attrs;
      default = { };
    };
    upstreams = mkOption {
      type = types.attrs;
      default = { };
    };
  };

  config = mkIf cfg.enable {
    services.nginx = {
      inherit (cfg) enable upstreams;

      virtualHosts = mkMerge [
        {
          "${cfg.fqdn}" = {
            locations."/stub_status" = {
              extraConfig = ''
                stub_status;
              '';
            };
          };
        }
        cfg.virtualHosts
      ];

      package =
        pkgs.nginx.override { modules = [ pkgs.nginxModules.fancyindex ]; };

      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
    };

    security.acme = {
      acceptTerms = true;
      defaults.email = cfg.acme.email;
    };

    networking.firewall = {
      allowedTCPPorts = [ 80 443 ];
      allowedUDPPorts = [ 80 443 ];
    };
  };
}
