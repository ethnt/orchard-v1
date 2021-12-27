{ config, pkgs, lib, ... }: {
  deployment.keys = {
    tailscale-auth-key = {
      keyFile = ../secrets/tailscale-auth-key;
    };
  };

  imports = [ ../modules ];

  time.timeZone = "America/New_York";

  networking.firewall = { enable = true; };

  environment.systemPackages = with pkgs; [ htop ];

  orchard = {
    services = {
      openssh.enable = true;

      tailscale = {
        enable = lib.mkDefault true;
        authKeyFile = config.deployment.keys.tailscale-auth-key.path;
      };
    };
  };
}
