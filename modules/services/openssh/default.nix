{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.openssh;
in {
  options.orchard.services.openssh = {
    enable = mkEnableOption "Enable OpenSSH";
    openFirewall = mkOption {
      type = types.bool;
      default = false;
    };
    port = mkOption {
      type = types.port;
      default = 22;
    };
  };

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;
      ports = [ cfg.port ];
    };

    networking.firewall =
      mkIf cfg.openFirewall { allowedTCPPorts = [ cfg.port ]; };
  };
}
