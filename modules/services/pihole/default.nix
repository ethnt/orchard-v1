{ config, pkgs, lib, ... }:

with lib;

let cfg = config.orchard.services.pihole;
in {
  options.orchard.services.pihole = {
    enable = mkEnableOption "Enable PiHole";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.pihole = {
      image = "docker.io/pihole/pihole:latest";
      ports =
        [ "53:53/tcp" "53:53/udp" "67:67/udp" "8000:80/tcp" "4433:443/tcp" ];
      environment = { TZ = "America/New_York"; };
      volumes =
        [ "/etc/pihole/:/etc/pihole/" "/etc/dnsmasq.d/:/etc/dnsmasq.d/" ];
      extraOptions = [ "--cap-add=NET_ADMIN" ];
      autoStart = true;
      log-driver = "journald";
    };

    networking.firewall = {
      allowedTCPPorts = [ 53 80 8000 4433 ];
      allowedUDPPorts = [ 53 67 ];
    };
  };
}
