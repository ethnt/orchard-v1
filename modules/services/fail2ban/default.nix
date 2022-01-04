{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.fail2ban;
in {
  options.orchard.services.fail2ban = {
    enable = mkEnableOption "Enable fail2ban";
    maxRetries = mkOption {
      type = types.int;
      default = 5;
    };
    allowlist = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
  };

  config = mkIf cfg.enable {
    services.fail2ban = {
      enable = true;
      maxretry = cfg.maxRetries;
      ignoreIP = cfg.allowlist;
    };
  };
}
