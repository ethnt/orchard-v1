{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.traefik;
in {
  options.orchard.services.traefik = {
    enable = mkEnableOption "Enable Traefik";
    staticConfig = mkOption {
      type = types.attrs;
      default = { };
    };
    dynamicConfig = mkOption {
      type = types.attrs;
      default = { };
    };
  };

  config = mkIf cfg.enable {
    services.traefik = {
      enable = true;
      staticConfigOptions = mkMerge [
        cfg.staticConfig
        {
          log = { level = "DEBUG"; };
          accessLog.filePath = "/var/lib/traefik/traefik.access.log";
          api = { dashboard = true; };
          entryPoints = {
            web = {
              address = ":80";
              http.redirections.entryPoint = {
                to = "websecure";
                scheme = "https";
              };
            };
            websecure = { address = ":443"; };
          };
          certificatesResolvers.letsEncrypt.acme = {
            tlsChallenge = true;
            email = "ethan.turkeltaub@hey.com";
            storage = "/var/lib/traefik/acme.json";
          };
        }
      ];
      dynamicConfigOptions = mkMerge [
        cfg.dynamicConfig
        {
          http = {
            routers = {
              traefik = {
                entrypoints = [ "websecure" ];
                rule = "Host(`traefik.orchard.computer`)";
                service = "api@internal";

                tls = {
                  certResolver = "letsEncrypt";
                  domains = [{
                    main = "traefik.orchard.computer";
                    sans = [ "*.traefik.orchard.computer" ];
                  }];
                };
              };
            };
          };
        }
      ];
    };
  };
}
