{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.nebula;
in {
  options.orchard.services.nebula = {
    enable = mkEnableOption "Enable Nebula networking";
    isLighthouse = mkOption {
      type = types.bool;
      default = false;
    };
    staticHostMap = mkOption {
      type = types.attrs;
      default = { };
    };
    caCert = mkOption { type = types.path; };
    hostKey = mkOption { type = types.path; };
    hostCert = mkOption { type = types.path; };
    lighthouses = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
  };

  config = mkIf cfg.enable {
    services.nebula.networks.orchard = {
      inherit (cfg) enable isLighthouse lighthouses staticHostMap;

      ca = cfg.caCert;
      key = cfg.hostKey;
      cert = cfg.hostCert;
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
        stats = {
          listen = "0.0.0.0:4243";
          type = "prometheus";
          path = "/metrics";
          subsystem = "nebula";
          interval = "10s";
        };
      };
    };

    networking.firewall = {
      allowedUDPPorts = [ 4242 4243 ];
      allowedTCPPorts = [ 4242 4243 ];
    };
  };
}
