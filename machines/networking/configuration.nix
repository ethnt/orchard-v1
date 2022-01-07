{ config, pkgs, resources, nodes, ... }:
let
  awsConfig = import ../../config/aws.nix;
  host = "networking.orchard.computer";
in {
  deployment = {
    targetEnv = "ec2";
    ec2 = {
      inherit (awsConfig) region;

      instanceType = "t3.micro";
      keyPair = resources.ec2KeyPairs.deployment-key;
      associatePublicIpAddress = true;
      subnetId = resources.vpcSubnets.public-subnet;
      securityGroupIds = [
        resources.ec2SecurityGroups.ssh-security-group.name
        resources.ec2SecurityGroups.prometheus-node-exporter-security-group.name
        resources.ec2SecurityGroups.tailscale-security-group.name
        resources.ec2SecurityGroups.http-security-group.name
        resources.ec2SecurityGroups.dns-security-group.name
      ];
      ebsBoot = true;
      ebsInitialRootDiskSize = 15;
    };
  };

  sops.secrets = { pihole_environment_file = { sopsFile = ./secrets.yaml; }; };

  orchard = {
    services = {
      prometheus-exporter = {
        inherit host;

        enable = true;
        node = {
          enable = true;
          openFirewall = true;
        };
      };

      promtail = {
        inherit host;

        enable = true;
        lokiServerConfiguration = {
          host = nodes.monitor.config.orchard.services.loki.host;
          port = nodes.monitor.config.orchard.services.loki.port;
        };
      };

      nginx = {
        enable = true;
        acme.email = "ethan.turkeltaub+orchard-computer@hey.com";
      };

      adguard = {
        enable = true;
        openFirewall = true;
        nginx = {
          enable = true;
          host = "adguard.orchard.computer";
        };
      };

      blocky = {
        enable = false;
        configuration = {
          upstream = { default = [ "1.1.1.1" "1.0.0.1" ]; };

          blocking = {
            blackLists = {
              ads = [
                "https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt"
                "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
                "https://mirror1.malwaredomains.com/files/justdomains"
                "http://sysctl.org/cameleon/hosts"
                "https://zeustracker.abuse.ch/blocklist.php?download=domainblocklist"
                "https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt"
              ];
            };

            blockType = "zeroIp";
          };

          caching = {
            minTime = "5m";
            maxTime = -1;
            maxItemsCount = 0;
            prefetching = true;
            prefetchExpires = "2h";
            prefetchThreshold = 5;
            prefetchMaxItemsCount = 0;
          };

          prometheus = {
            enable = true;
            path = "/metrics";
          };

          httpPort = 4000;
        };
      };
    };
  };
}
