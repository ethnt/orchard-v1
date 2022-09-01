{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.hercules-ci-agent;
in {
  options.orchard.services.hercules-ci-agent = {
    enable = mkEnableOption "Enable the Hercules CI agent";
    binaryCachesPath = mkOption { type = types.path; };
    clusterJoinTokenPath = mkOption { type = types.path; };
    labels = mkOption { type = types.anything; };
  };

  config = mkIf cfg.enable {
    services.hercules-ci-agent = {
      inherit (cfg) enable;
      settings = {
        inherit (cfg) clusterJoinTokenPath binaryCachesPath;
        concurrentTasks = 4;
      };
    };

    systemd.services.hercules-ci-agent = {
      serviceConfig.SupplementaryGroups = [ config.users.groups.keys.name ];
    };
  };
}
