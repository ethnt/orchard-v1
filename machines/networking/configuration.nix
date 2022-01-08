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
        resources.ec2SecurityGroups.networking-security-group.name
      ];
      ebsBoot = true;
      ebsInitialRootDiskSize = 15;
    };
  };

  environment.systemPackages = with pkgs; [ iftop nethogs ];

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

      blocky = {
        enable = true;
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

            whiteLists = {
              ads = [''
                analytics.google.com
                tagmanager.google.com
              ''];
            };

            clientGroupsBlock = { default = [ "ads" ]; };

            blockType = "zeroIp";
          };

          caching = {
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
