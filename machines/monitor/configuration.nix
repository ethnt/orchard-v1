{ config, pkgs, resources, ... }:
let aws = import ../../config/aws.nix;
in {
  deployment = {
    targetEnv = "ec2";
    ec2 = {
      inherit (aws) region;

      instanceType = "t3.small";
      keyPair = resources.ec2KeyPairs.deployment-key;
      securityGroups = [
        resources.ec2SecurityGroups.ssh-security-group
        resources.ec2SecurityGroups.tailscale-security-group
      ];
      ebsBoot = true;
      ebsInitialRootDiskSize = 50;
    };
  };

  orchard = { };
}
