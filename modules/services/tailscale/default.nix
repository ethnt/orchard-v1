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

    hostname = mkOption { type = types.str; };

    namespace = mkOption { type = types.str; };

    fqdn = mkOption {
      type = types.str;
      default = "${cfg.hostname}.${cfg.namespace}";
    };

    loginServer = mkOption {
      type = types.str;
      default = "https://headscale.orchard.computer:443";
    };

    advertiseExitNode = mkOption {
      type = types.bool;
      default = false;
    };

    exitNode = mkOption {
      type = types.string;
      default = "";
    };

    authKeyFile = mkOption { type = types.str; };
  };

  config = mkIf cfg.enable {
    services.tailscale = { inherit (cfg) enable port; };

    networking.firewall =
      mkIf cfg.openFirewall { allowedUDPPorts = [ cfg.port ]; };

    systemd.services.tailscaled.wants = [ "tailscaled.service" ];
    systemd.services."tailscaled-autoconnect" = {
      serviceConfig.Type = "oneshot";

      after = [ "tailscaled.service" ];
      wantedBy = [ "tailscaled.service" ];

      script = ''
        # Wait for tailscaled to be ready
        sleep 2

        # Check if we're already using Tailscale
        status="$(${pkgs.tailscale}/bin/tailscale status -json | ${pkgs.jq}/bin/jq -r .BackendState)"
        if [ $status = "Running" ]; then
          exit 0
        fi

        if [ -f "${cfg.authKeyFile}" ]; then
          ${pkgs.tailscale}/bin/tailscale up \
            --auth-key=file:${cfg.authKeyFile} \
            --login-server=${cfg.loginServer} \
            --hostname=${cfg.hostname}
        fi
      '';
    };
  };
}
