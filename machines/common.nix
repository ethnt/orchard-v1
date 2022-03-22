{ config, pkgs, lib, ... }: {
  sops = {
    # Set the secrets file location
    defaultSopsFile = ./secrets.yaml;

    secrets = {
      nebula_ca_cert = { };
      aws_credentials = { };
      backup_password = { };
    };
  };

  imports = [ ../modules ];

  time.timeZone = "America/New_York";

  system.autoUpgrade.channel = "https://nixos.org/channels/nixos-21.11/";

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
      nebula = {
        network = {
          name = "orchard";
          caPath = config.sops.secrets.nebula_ca_cert.path;
        };
      };

      openssh.enable = true;

      zerotier = {
        enable = true;
        networkId = "9bee8941b5fb2362";
      };
    };
  };
}
