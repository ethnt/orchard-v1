{ config, pkgs, resources, nodes, ... }: {
  deployment = { targetHost = "192.168.1.44"; };

  imports = [ ../qemu.nix ./hardware-configuration.nix ];

  sops = {
    secrets = {
      nebula_host_key = { sopsFile = ./secrets.yaml; };
      nebula_host_cert = { sopsFile = ./secrets.yaml; };
    };
  };

  boot.initrd.kernelModules = [ "i915" ];

  hardware.opengl.extraPackages = with pkgs; [
    vaapiIntel
    vaapiVdpau
    libvdpau-va-gl
    intel-media-driver
  ];

  # TODO: Make other systemd services (sonarr, etc) require mount to finish first
  fileSystems."/mnt/omnibus" = {
    device = "192.168.1.12:/mnt/omnibus/htpc";
    fsType = "nfs";
    options = [
      "noauto"
      "x-systemd.automount"
      "x-systemd.requires=network-online.target"
      "x-systemd.device-timeout=10"
    ];
  };

  users.groups.htpc = {
    gid = 1042;
    members = [ "nzbget" "sonarr" "radarr" "plex" ];
  };

  users.users.htpc = {
    uid = 1042;
    isSystemUser = true;
    isNormalUser = false;
    group = config.users.groups.htpc.name;
  };

  orchard = {
    services = {
      nebula = {
        enable = true;
        network = {
          lighthouses = [ "10.10.10.1" ];
          staticHostMap = {
            "10.10.10.1" =
              [ "${nodes.gateway.config.deployment.targetHost}:4242" ];
          };
        };
        host = {
          addr = "10.10.10.2";
          keyPath = config.sops.secrets.nebula_host_key.path;
          certPath = config.sops.secrets.nebula_host_cert.path;
        };
      };

      sonarr = {
        enable = true;
        openFirewall = true;
        group = "htpc";
      };

      radarr = {
        enable = true;
        openFirewall = true;
        group = "htpc";
      };

      plex = {
        enable = true;
        openFirewall = true;
        group = "htpc";
      };

      nzbget = {
        enable = true;
        openFirewall = true;
        group = "htpc";
      };
    };
  };
}
