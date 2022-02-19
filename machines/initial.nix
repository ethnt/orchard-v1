{ config, pkgs, lib, ... }: {
  imports = [ ../modules ];

  time.timeZone = "America/New_York";

  networking.firewall = { enable = true; };

  orchard = {
    programs = { fish.enable = true; };
    services = { openssh.enable = true; };
  };
}
