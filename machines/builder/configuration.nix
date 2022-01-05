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
        resources.ec2SecurityGroups.prometheus-node-exporter-security-group
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
