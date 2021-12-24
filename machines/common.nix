{ config, pkgs, ... }: {
  imports = [ ../modules ];

  time.timeZone = "America/New_York";

  networking.firewall = { enable = true; };

  environment.systemPackages = with pkgs; [ htop ];

  orchard = { services = { openssh.enable = true; }; };
}
