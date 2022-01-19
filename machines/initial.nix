{ config, pkgs, lib, ... }: {
  imports = [ ../modules ../programs ];

  time.timeZone = "America/New_York";

  networking.firewall = { enable = true; };

  environment.systemPackages = with pkgs; [ dig htop nix-index tmux ];

  orchard = {
    programs = { fish.enable = true; };

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
    };
  };
}
