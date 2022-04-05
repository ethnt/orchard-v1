{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.miniflux;
in {
  options.orchard.services.miniflux = {
    enable = mkEnableOption "Enable Miniflux";
    config = mkOption {
      type = types.attrs;
      default = { };
    };
    credentialsFile = mkOption { type = types.str; };
  };

  config = mkIf cfg.enable {
    services.miniflux = {
      enable = true;
      config = mkMerge [ { POLLING_FREQUENCY = "15"; } cfg.config ];
      adminCredentialsFile = cfg.credentialsFile;
    };
  };
}
