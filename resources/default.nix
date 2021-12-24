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

    pihole-security-group = {
      inherit (awsConfig) region;

      description = "Security group for PiHole";
      rules = [{
        fromPort = 8000;
        toPort = 8000;
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
    funnel-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "funnel.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.funnel ];
    };
  };
}
