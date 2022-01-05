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

    http-security-group = {
      inherit (awsConfig) region;

      description = "Security group for HTTP networking";
      rules = [
        {
          fromPort = 80;
          toPort = 80;
          sourceIp = "0.0.0.0/0";
        }
        {
          fromPort = 443;
          toPort = 443;
          sourceIp = "0.0.0.0/0";
        }
      ];
    };

    prometheus-security-group = {
      inherit (awsConfig) region;

      description = "Security group for Prometheus monitoring";
      rules = [{
        fromPort = 9001;
        toPort = 9001;
        sourceIp = "0.0.0.0/0";
      }];
    };

    prometheus-node-exporter-security-group = {
      inherit (awsConfig) region;

      description = "Security group for the Prometheus Node Exporter";
      rules = [{
        fromPort = 9002;
        toPort = 9002;
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

    grafana-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "grafana.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.monitor ];
    };
  };
}
