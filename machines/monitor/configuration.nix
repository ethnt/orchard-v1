{ config, lib, pkgs, resources, nodes, ... }:
let aws = import ../../config/aws.nix;
in {
  deployment = {
    targetEnv = "ec2";
    ec2 = {
      inherit (aws) region;

      instanceType = "t3.medium";
      keyPair = resources.ec2KeyPairs.deployment-key;
      securityGroups = [ resources.ec2SecurityGroups.monitor-security-group ];
      ebsBoot = true;
      ebsInitialRootDiskSize = 128;
    };
  };

  sops = {
    secrets = {
      nebula_host_key = { sopsFile = ./secrets.yaml; };
      nebula_host_cert = { sopsFile = ./secrets.yaml; };
    };
  };

  orchard = {
    services = {
      nebula = {
        enable = true;
        network = {
          lighthouses = [ "10.10.10.1" ];
          staticHostMap = {
            "10.10.10.1" =
              [ "${nodes.gateway.config.networking.publicIPv4}:4242" ];
            "10.10.10.2" =
              [ "${nodes.gateway.config.networking.publicIPv4}:4343" ];
          };
        };
        host = {
          addr = "10.10.10.4";
          keyPath = config.sops.secrets.nebula_host_key.path;
          certPath = config.sops.secrets.nebula_host_cert.path;
        };
      };
    };
  };
}
