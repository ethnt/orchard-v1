{ config, pkgs, resources, nodes, ... }: {
  deployment = { targetHost = "192.168.1.183"; };

  sops.secrets = {
    # nebula_ca_cert = { sopsFile = ../secrets.yaml; };
    # nebula_host_key = { sopsFile = ./secrets.yaml; };
    # nebula_host_cert = { sopsFile = ./secrets.yaml; };
  };

  networking.publicIPv4 = "192.168.1.183";
  networking.privateIPv4 = "192.168.1.183";

  imports = [ ./hardware-configuration.nix ];

  services.qemuGuest.enable = true;

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  fileSystems."/mnt/omnibus" = {
    device = "192.168.1.190:/volume1/barbossa";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "noauto"
    ]; # Don't mount until it's first accessed
  };

  users.groups.media = { members = [ "nzbget" "sonarr" "radarr" "plex" ]; };

  # users.users.media = {
  #   isSystemUser = true;
  #   isNormalUser = false;
  #   createHome = false;
  #   group = config.users.groups.media.name;
  #   extraGroups = [ "wheel" ];
  # };

  # services.qemuGuest = {
  #   enable = true;
  #   package = pkgs.unstable.qemu_kvm.ga;
  # };

  networking.firewall = {
    allowedTCPPorts = [ 8080 ];
    allowedUDPPorts = [ 8080 ];
  };

  orchard = {
    services = {
      # nebula = {
      #   enable = true;
      #   caCert = config.sops.secrets.nebula_ca_cert.path;
      #   hostKey = config.sops.secrets.nebula_host_key.path;
      #   hostCert = config.sops.secrets.nebula_host_cert.path;
      #   staticHostMap = {
      #     "10.11.12.1" =
      #       [ "${nodes.bastion.config.networking.publicIPv4}:4242" ];
      #   };
      #   lighthouses = [ "10.11.12.1" ];
      # };

      prometheus-exporter = {
        enable = true;
        host = "htpc.orchard.computer";
        node = {
          enable = true;
          openFirewall = true;
        };
      };

      promtail = {
        enable = true;
        host = "htpc";
        lokiServerConfiguration = {
          host = nodes.monitor.config.networking.privateIPv4;
          port = nodes.monitor.config.orchard.services.loki.port;
        };
      };

      sonarr = {
        enable = true;
        openFirewall = true;
        group = "media";
      };

      radarr = {
        enable = true;
        openFirewall = true;
        group = "media";
      };

      plex = {
        enable = true;
        openFirewall = true;
        group = "media";
      };

      nzbget = {
        enable = true;
        openFirewall = true;
        group = "media";
      };

      tautulli = {
        enable = true;
        openFirewall = true;
        group = "media";
      };
    };
  };
}
