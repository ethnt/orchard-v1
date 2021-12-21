{ config, pkgs, ... }: {
  environment.systemPackages = with pkgs; [ htop ];

  services.openssh = {
    enable = true;
    passwordAuthentication = false;
  };

  networking.firewall = {
    enable = false;
    allowedTCPPorts = [ 22 ];
    allowedUDPPorts = [ 22 ];
  };
}
