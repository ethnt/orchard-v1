{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.orchard.services.headscale;
  settingsFormat = pkgs.formats.yaml { };
in {
  options.orchard.services.headscale = {
    enable = mkEnableOption "Enable Headscale server";
    package = mkOption {
      type = types.package;
      default = pkgs.headscale;
    };
    externalServerUrl = mkOption { type = types.str; };
    namespaces = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
    extraSettings = mkOption {
      type = settingsFormat.type;
      default = { };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    services.headscale = {
      inherit (cfg) enable package;
      serverUrl = cfg.externalServerUrl;
      dns = {
        baseDomain = "";
        magicDns = true;
      };
      settings =
        mkMerge [ { grpc_listen_addr = "127.0.0.1:50443"; } cfg.extraSettings ];
    };

    systemd.services."headscale-provisioning" = {
      serviceConfig.Type = "oneshot";

      after = [ "headscale.service" ];
      wantedBy = [ "headscale.service" ];

      script = ''
        # Wait for headscale to be ready
        sleep 2

        ${concatStringsSep "\n" (map (namespace:
          "${cfg.package}/bin/headscale namespaces create ${namespace}")
          cfg.namespaces)}
      '';
    };
  };
}
