{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.apcupsd;
in {
  options.orchard.services.apcupsd = {
    enable = mkEnableOption "Enable APC UPS daemon";
    configText = mkOption {
      type = types.lines;
      default = "";
    };
  };

  config = mkIf cfg.enable {
    services.apcupsd = { inherit (cfg) enable configText; };
  };
}
