{ config, pkgs, lib, ... }: {
  sops = {
    defaultSopsFile = ./secrets.yaml;

    secrets = {
      aws_credentials = { };
      backup_password = { };
    };
  };

  imports = [ ../modules ../profiles/ssh-user ];

  time.timeZone = "America/New_York";

  system.autoUpgrade.channel = "https://nixos.org/channels/nixos-22.05/";

  networking.firewall.enable = true;

  environment.systemPackages = with pkgs; [
    bat
    dig
    du-dust
    htop
    nix-index
    tmux
  ];

  orchard = {
    programs.fish.enable = true;

    services = {
      mosh.enable = true;

      openssh = {
        enable = true;
        openFirewall = true;
      };
    };
  };
}
