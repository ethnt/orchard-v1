{ config, pkgs, lib, ... }:

with lib;

let cfg = config.orchard.services.docker;
in {
  options.orchard.services.docker = {
    enable = mkEnableOption "Enable containers with Docker";
  };

  config = mkIf cfg.enable {
    virtualisation = {
      docker = { enable = true; };

      oci-containers.backend = "docker";
    };
  };
}
