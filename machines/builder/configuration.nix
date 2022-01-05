{ config, pkgs, resources, ... }:
let awsConfig = import ../../config/aws.nix;
in {
  deployment = {
    targetEnv = "ec2";
    ec2 = {
      inherit (awsConfig) region;

      instanceType = "t3.small";
      keyPair = resources.ec2KeyPairs.deployment-key;
      associatePublicIpAddress = true;
      subnetId = resources.vpcSubnets.public-subnet;
      securityGroupIds = [
        resources.ec2SecurityGroups.ssh-security-group.name
        resources.ec2SecurityGroups.prometheus-node-exporter-security-group.name
        resources.ec2SecurityGroups.tailscale-security-group.name
      ];
      ebsBoot = true;
      ebsInitialRootDiskSize = 50;
    };
  };

  orchard = {
    services = {
      prometheus-exporter = {
        enable = true;
        host = "builder.orchard.computer";
        node = {
          enable = true;
          openFirewall = true;
        };
      };

      remote-builder = {
        enable = true;
        emulatedSystems = [ "aarch64-linux" ];
        buildUserKeyFile = ./keys/builder.pub;
      };
    };
  };
}
