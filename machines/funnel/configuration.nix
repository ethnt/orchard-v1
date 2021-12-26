{ config, pkgs, resources, ... }:
let awsConfig = import ../../config/aws.nix;
in {
  deployment = {
    targetEnv = "ec2";
    ec2 = {
      inherit (awsConfig) region;

      instanceType = "t3.micro";
      keyPair = resources.ec2KeyPairs.deployment-key;
      securityGroups = [
        resources.ec2SecurityGroups.ssh-security-group
        resources.ec2SecurityGroups.pihole-security-group
      ];
      ebsBoot = true;
      ebsInitialRootDiskSize = 15;
    };

    keys = {
      # nebula-crt = { keyFile = ../../modules/services/nebula/keys/ca.crt; };
      nebula-funnel-crt = { keyFile = ./keys/funnel.crt; };
      nebula-funnel-key = { keyFile = ./keys/funnel.key; };
    };
  };

  orchard = {
    services = {
      docker = { enable = true; };
      pihole = { enable = true; };
    };
  };

  services.nebula.networks = {
    orchard = {
      enable = true;
      staticHostMap = { "192.168.100.1" = [ "192.168.100.1:4242" ]; };
      # ca = "/run/keys/nebula-crt";
      ca = config.deployment.keys.nebula-crt.path;
      cert = "/run/keys/nebula-funnel-crt";
      key = "/run/keys/nebula-funnel-key";
      lighthouses = [ "192.168.100.1" ];
    };
  };
}
