{ config, lib, pkgs, resources, nodes, ... }:
let aws = import ../../config/aws.nix;
in {
  deployment = {
    targetEnv = "ec2";
    ec2 = {
      inherit (aws) region;

      ami = "ami-067611519fa817aaa";
      instanceType = "t4g.micro";
      keyPair = resources.ec2KeyPairs.deployment-key;
      securityGroups = [ resources.ec2SecurityGroups.branch-security-group ];
      ebsBoot = true;
      ebsInitialRootDiskSize = 64;
      elasticIPv4 = resources.elasticIPs.branch-elastic-ip;
    };
  };

  sops = {
    secrets = {
      tailscale_auth_key = { sopsFile = ./secrets.yaml; };
      github_runner_token = { sopsFile = ./secrets.yaml; };
    };
  };

  orchard = {
    services = {
      tailscale = {
        enable = true;
        openFirewall = true;
        authKeyFile = config.sops.secrets.tailscale_auth_key.path;
        hostname = "branch";
        namespace = "orchard";
      };

      remote-builder = {
        enable = true;
        emulatedSystems = [ ];
        buildUserPublicKeyFile = ../matrix/remote-builder/builder.pub;
      };

      promtail = {
        enable = true;
        host = "branch";
        lokiServerConfiguration = {
          host = nodes.monitor.config.orchard.services.loki.host;
          port = nodes.monitor.config.orchard.services.loki.port;
        };
      };

      prometheus-node-exporter = {
        enable = true;
        host = "branch.orchard.computer";
        openFirewall = true;
      };

      github-runner = {
        enable = false;
        url = "https://github.com/ethnt/orchard";
        tokenFile = config.sops.secrets.github_runner_token.path;
      };
    };
  };
}
