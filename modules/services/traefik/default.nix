{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.traefik;
in {
  options.orchard.services.traefik = {
    enable = mkEnableOption "Enable Traefik";
  };

  config = mkIf cfg.enable { services.traefik = { enable = true; }; };
}
