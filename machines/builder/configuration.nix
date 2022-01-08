{ config, pkgs, resources, nodes, ... }:
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
      securityGroupIds =
        [ resources.ec2SecurityGroups.builder-security-group.name ];
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

      promtail = {
        enable = true;
        host = "builder.orchard.computer";
        lokiServerConfiguration = {
          host = nodes.monitor.config.orchard.services.loki.host;
          port = nodes.monitor.config.orchard.services.loki.port;
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
