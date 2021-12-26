{ config, pkgs, ... }: {
  deployment = {
    keys = {
      nebula-crt = { keyFile = ../modules/services/nebula/keys/ca.crt; };
    };
  };

  imports = [ ../modules ];

  time.timeZone = "America/New_York";

  networking.firewall = { enable = true; };

  environment.systemPackages = with pkgs; [ htop nebula ];

  orchard = {
    services = {
      openssh.enable = true;
      # zerotierone = {
      #   enable = true;
      #   joinNetworks = [ "8bd5124fd6b8e05c" ];
      # };
    };
  };
}
