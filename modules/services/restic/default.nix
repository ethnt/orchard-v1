{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.restic;
in {
  options.orchard.services.restic = {
    enable = mkEnableOption "Enable Restic backups";
    backupName = mkOption { type = types.str; };
    paths = mkOption { type = types.listOf types.str; };
    s3 = mkOption {
      type = types.submodule {
        options = {
          bucketName = mkOption { type = types.str; };
          credentialsFile = mkOption { type = types.str; };
        };
      };
    };
    passwordFile = mkOption { type = types.str; };
  };

  config = mkIf cfg.enable {
    services.restic.backups.${cfg.backupName} = {
      inherit (cfg) passwordFile paths;

      initialize = true;
      repository = "s3:s3.amazonaws.com/${cfg.s3.bucketName}";
      timerConfig = { OnCalendar = "daily"; };
      environmentFile = cfg.s3.credentialsFile;
    };
  };
}
