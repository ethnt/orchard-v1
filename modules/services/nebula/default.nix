{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.nebula;
in {
  options.orchard.services.nebula = {
    enable = mkEnableOption "Enable Nebula networking";
    network = mkOption {
      type = types.submodule {
        options = {
          name = mkOption { type = types.str; };

          caPath = mkOption { type = types.str; };

          lighthouses = mkOption {
            type = types.listOf types.str;
            default = [ ];
          };

          staticHostMap = mkOption {
            type = types.attrs;
            default = { };
          };
        };
      };
    };
    host = mkOption {
      type = types.submodule {
        options = {
          addr = mkOption {
            type = types.str;
            example = "10.10.10.2";
          };

          port = mkOption {
            type = types.port;
            default = 4242;
          };

          isLighthouse = mkOption {
            type = types.bool;
            default = false;
          };

          keyPath = mkOption { type = types.str; };

          certPath = mkOption { type = types.str; };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    services.nebula.networks.${cfg.network.name} = {
      enable = true;
      isLighthouse = cfg.host.isLighthouse;
      lighthouses = cfg.network.lighthouses;
      ca = cfg.network.caPath;
      key = cfg.host.keyPath;
      cert = cfg.host.certPath;
      staticHostMap = cfg.network.staticHostMap;
      listen = { port = cfg.host.port; };
      firewall = {
        inbound = [{
          host = "any";
          port = "any";
          proto = "any";
        }];
        outbound = [{
          host = "any";
          port = "any";
          proto = "any";
        }];
      };
      settings = {
        punchy = {
          punch = true;
          respond = true;
        };
      };
    };

    networking.firewall = {
      allowedUDPPorts = [ 4242 4243 ];
      allowedTCPPorts = [ 4242 4243 ];
    };
  };
}
