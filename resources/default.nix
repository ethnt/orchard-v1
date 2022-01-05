let
  awsConfig = import ../config/aws.nix;
  inherit (awsConfig) region;
in {
  ec2KeyPairs = { deployment-key = { inherit region; }; };

  ec2SecurityGroups = {
    http-security-group = { resources, ... }: {
      inherit region;

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
      vpcId = resources.vpc.vpc-orchard;
    };

    prometheus-security-group = { resources, ... }: {
      inherit region;

      description = "Security group for Prometheus monitoring";
      rules = [{
        fromPort = 9001;
        toPort = 9001;
        sourceIp = "0.0.0.0/0";
      }];
      vpcId = resources.vpc.vpc-orchard;
    };

    loki-security-group = { resources, ... }: {
      inherit region;

      description = "Security group for Loki log aggregation";
      rules = [{
        fromPort = 3100;
        toPort = 3100;
        sourceIp = "0.0.0.0/0";
      }];
      vpcId = resources.vpc.vpc-orchard;
    };

    prometheus-node-exporter-security-group = { resources, ... }: {
      inherit region;

      description = "Security group for the Prometheus Node Exporter";
      rules = [{
        fromPort = 9002;
        toPort = 9002;
        sourceIp = "0.0.0.0/0";
      }];
      vpcId = resources.vpc.vpc-orchard;
    };

    tailscale-security-group = { resources, ... }: {
      inherit region;

      description = "Security group for Tailscale networking";
      rules = [{
        fromPort = 41641;
        toPort = 41641;
        sourceIp = "0.0.0.0/0";
      }];
      vpcId = resources.vpc.vpc-orchard;
    };

    ssh-security-group = { resources, ... }: {
      inherit region;

      description = "Security group for SSH access";
      rules = [{
        fromPort = 22;
        toPort = 22;
        sourceIp = "0.0.0.0/0";
      }];
      vpcId = resources.vpc.vpc-orchard;
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

  vpc = {
    vpc-orchard = {
      inherit region;
      instanceTenancy = "default";
      enableDnsSupport = true;
      enableDnsHostnames = true;
      cidrBlock = "10.0.0.0/16";
    };
  };

  vpcSubnets = {
    public-subnet = { resources, ... }: {
      inherit region;
      zone = "${awsConfig.region}a";
      vpcId = resources.vpc.vpc-orchard;
      cidrBlock = "10.0.0.0/24";
      mapPublicIpOnLaunch = true;
    };
  };

  vpcRouteTables = {
    public-route-table = { resources, ... }: {
      inherit region;
      vpcId = resources.vpc.vpc-orchard;
    };
  };

  vpcRouteTableAssociations = {
    public-route-table-public-subnet-association = { resources, ... }: {
      inherit region;
      subnetId = resources.vpcSubnets.public-subnet;
      routeTableId = resources.vpcRouteTables.public-route-table;
    };
  };

  vpcRoutes = {
    internet-gateway-vpc-route = { resources, ... }: {
      inherit region;
      routeTableId = resources.vpcRouteTables.public-route-table;
      destinationCidrBlock = "0.0.0.0/0";
      gatewayId = resources.vpcInternetGateways.internet-gateway;
    };
  };

  vpcInternetGateways = {
    internet-gateway = { resources, ... }: {
      inherit region;
      vpcId = resources.vpc.vpc-orchard;
    };
  };

  elasticIPs = {
    nat-elastic-ip = {
      inherit region;
      vpc = true;
    };
  };

  vpcNatGateways = {
    nat-gateway = { resources, ... }: {
      inherit region;
      allocationId = resources.elasticIPs.nat-elastic-ip;
      subnetId = resources.vpcSubnets.public-subnet;
    };
  };
}
