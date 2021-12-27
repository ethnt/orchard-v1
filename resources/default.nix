let awsConfig = import ../config/aws.nix;
in {
  ec2KeyPairs = { deployment-key = { inherit (awsConfig) region; }; };

  ec2SecurityGroups = {
    ssh-security-group = {
      inherit (awsConfig) region;

      description = "Security group for SSH access";
      rules = [{
        fromPort = 22;
        toPort = 22;
        sourceIp = "0.0.0.0/0";
      }];
    };

    tailscale-security-group = {
      inherit (awsConfig) region;

      description = "Security group for Tailscale networking";
      rules = [{
        fromPort = 41641;
        toPort = 41641;
        sourceIp = "0.0.0.0/0";
      }];
    };
  };

  route53HostedZones = {
    orchard-computer = {
      name = "orchard.computer.";
      comment = "Hosted zone for orchard.computer";
    };
  };

  route53RecordSets = {
    builder-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "builder.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.builder ];
    };

    monitor-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "monitor.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.monitor ];
    };
  };
}
