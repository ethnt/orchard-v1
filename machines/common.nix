{ config, pkgs, lib, ... }: {
  sops = {
    # Set the secrets file location
    defaultSopsFile = ./secrets.yaml;

    # These are common secrets used among every machine
    secrets = { tailscale_auth_key = { sopsFile = ./secrets.yaml; }; };
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
        authKeyFile = config.sops.secrets.tailscale_auth_key.path;
      };
    };
  };
}
