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
  };

  config = mkIf cfg.enable {
    services.nginx = {
      enable = true;

      package =
        pkgs.nginx.override { modules = [ pkgs.nginxModules.fancyindex ]; };

      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
    };

    security.acme = {
      acceptTerms = true;
      email = cfg.acme.email;
    };

    networking.firewall = {
      allowedTCPPorts = [ 80 443 ];
      allowedUDPPorts = [ 80 443 ];
    };
  };
}
