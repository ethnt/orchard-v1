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

  environment.systemPackages = with pkgs; [ dig htop ];

  orchard = {
    services = {
      fail2ban = {
        enable = lib.mkDefault true;
        allowlist = [
          "127.0.0.0/8"
          "10.0.0.0/8"
          "100.0.0.0/8"
          "172.16.0.0/12"
          "192.168.0.0/16"
          "8.8.8.8"
        ];
      };

      openssh.enable = true;

      tailscale = {
        enable = lib.mkDefault true;
        authKeyFile = config.sops.secrets.tailscale_auth_key.path;
      };
    };
  };
}
