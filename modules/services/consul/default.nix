{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.consul;
in {
  options.orchard.services.consul = {
    enable = mkEnableOption "Enable Consul";
    web = mkOption {
      type = types.submodule {
        options = {
          enable = mkEnableOption "Enable Consul web UI";
          port = mkOption {
            type = types.port;
            default = 8500;
          };
          openFirewall = mkOption {
            type = types.bool;
            default = true;
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    services.consul = {
      enable = true;
      webUi = cfg.web.enable;
      interface.bind = "ens18";
      extraConfig = { client_addr = "0.0.0.0"; };
    };

    networking.firewall = mkIf cfg.web.openFirewall {
      allowedTCPPorts = [ cfg.web.port ];
      allowedUDPPorts = [ cfg.web.port ];
    };
  };
}
