{ config, pkgs, resources, ... }:
let awsConfig = import ../../config/aws.nix;
in {
  deployment = {
    targetEnv = "ec2";
    ec2 = {
      inherit (awsConfig) region;

      instanceType = "t3.nano";
      keyPair = resources.ec2KeyPairs.deployment-key;
      securityGroups = [
        resources.ec2SecurityGroups.ssh-security-group
        resources.ec2SecurityGroups.nebula-security-group
      ];
      ebsBoot = true;
      ebsInitialRootDiskSize = 5;
    };

    keys = {
      # nebula-crt = { keyFile = ../../modules/services/nebula/keys/ca.crt; };
      nebula-lighthouse-crt = { keyFile = ./keys/lighthouse.crt; };
      nebula-lighthouse-key = { keyFile = ./keys/lighthouse.key; };
    };
  };

  orchard = { };

  services.nebula.networks = {
    orchard = {
      enable = true;
      isLighthouse = true;
      ca = "/run/keys/nebula-crt";
      cert = "/run/keys/nebula-lighthouse-crt";
      key = "/run/keys/nebula-lighthouse-key";
    };
  };
}
