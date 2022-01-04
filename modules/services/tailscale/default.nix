{ config, pkgs, lib, ... }:

with lib;

let cfg = config.orchard.services.tailscale;
in {
  options.orchard.services.tailscale = {
    enable = mkEnableOption "Enable networking with Tailscale";

    port = mkOption {
      type = types.port;
      default = 41641;
    };

    openFirewall = mkOption {
      type = types.bool;
      default = true;
    };

    authKeyFile = mkOption { type = types.str; };
  };

  config = mkIf cfg.enable {
    services.tailscale = { inherit (cfg) enable port; };

    networking.firewall =
      mkIf cfg.openFirewall { allowedUDPPorts = [ cfg.port ]; };

    systemd.services."tailscale-authentication" = {
      serviceConfig.Type = "oneshot";

      after = [ "tailscaled.service" ];
      wantedBy = [ "tailscaled.service" ];

      script = ''
        ${pkgs.tailscale}/bin/tailscale up \
          --authkey=$(cat ${cfg.authKeyFile}) \
      '';
    };
  };
}
