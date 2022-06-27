{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.mosh;
in {
  options.orchard.services.mosh = { enable = mkEnableOption "Enable Mosh"; };

  config = mkIf cfg.enable { programs.mosh.enable = true; };
}
