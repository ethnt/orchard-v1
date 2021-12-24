{ config, pkgs, resources, ... }:
let awsConfig = import ../../config/aws.nix;
in {
  deployment = {
    targetEnv = "ec2";
    ec2 = {
      inherit (awsConfig) region;

      instanceType = "t3.micro";
      keyPair = resources.ec2KeyPairs.deployment-key;
      securityGroups = [ resources.ec2SecurityGroups.ssh-security-group ];
      ebsBoot = true;
      ebsInitialRootDiskSize = 50;
    };
  };

  orchard = {
    services = {
      remote-builder = {
        enable = true;
        emulatedSystems = [ "aarch64-linux" ];
      };
    };
  };
}
