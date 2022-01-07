{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.orchard.services.blocky;
  jsonValue = with types;
    let
      valueType = nullOr (oneOf [
        bool
        int
        float
        str
        (lazyAttrsOf valueType)
        (listOf valueType)
      ]) // {
        description = "JSON value";
        emptyValue.value = { };
      };
    in valueType;
  configFile = pkgs.runCommand "config.yaml" {
    buildInputs = [ pkgs.remarshal ];
    preferLocalBuild = true;
  } ''
    remarshal -if json -of yaml \
      < ${
        pkgs.writeText "dynamic_config.json" (builtins.toJSON cfg.configuration)
      } \
      > $out
      '';
in {
  options.orchard.services.blocky = {
    enable = mkEnableOption "Enable the Blocky DNS server";

    package = mkOption {
      default = pkgs.blocky;
      type = types.package;
    };

    configuration = mkOption {
      type = jsonValue;
      default = null;
    };
  };

  config = mkIf cfg.enable {
    users.groups.blocky = { };

    users.users.blocky = {
      group = config.users.groups.blocky.name;
      createHome = false;
      isSystemUser = true;
    };

    systemd.services.blocky = {
      description = "Blocky DNS server";
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      startLimitIntervalSec = 86400;
      startLimitBurst = 5;
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/blocky --config=${configFile}";
        Type = "simple";
        User = config.users.users.blocky.name;
        Group = config.users.groups.blocky.name;
        Restart = "on-failure";
        AmbientCapabilities = "cap_net_bind_service";
        CapabilityBoundingSet = "cap_net_bind_service";
        NoNewPrivileges = true;
        LimitNPROC = 64;
        LimitNOFILE = 1048576;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectHome = true;
        ProtectSystem = "full";
      };
    };

    networking.firewall = {
      allowedTCPPorts = [ 53 4000 ];
      allowedUDPPorts = [ 53 ];
    };

    services.nginx = {
      virtualHosts."blocky.orchard.computer" = {
        http2 = true;
        addSSL = true;
        enableACME = true;

        locations."/" = { proxyPass = "http://0.0.0.0:4000"; };
      };
    };
  };
}
