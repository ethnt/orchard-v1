{ config, pkgs, resources, ... }:
let awsConfig = import ../../config/aws.nix;
in {
  deployment = {
    targetEnv = "ec2";
    ec2 = {
      inherit (awsConfig) region;

      instanceType = "t3.small";
      keyPair = resources.ec2KeyPairs.deployment-key;
      securityGroups = [
        resources.ec2SecurityGroups.ssh-security-group
        resources.ec2SecurityGroups.tailscale-security-group
      ];
      ebsBoot = true;
      ebsInitialRootDiskSize = 50;
    };

    keys = { ssh-builder-key = { keyFile = ./keys/builder.pub; }; };
  };

  orchard = {
    services = {
      remote-builder = {
        enable = true;
        emulatedSystems = [ "aarch64-linux" ];
        buildUserKey = builtins.readFile ./keys/builder.pub;
      };
    };
  };
}
