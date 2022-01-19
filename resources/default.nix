let
  awsConfig = import ../config/aws.nix;
  inherit (awsConfig) region;
in {
  ec2KeyPairs = { deployment-key = { inherit region; }; };

  ec2SecurityGroups = let
    mkRule = { protocol ? "tcp", port, sourceIp ? "0.0.0.0/0" }: {
      inherit protocol sourceIp;
      fromPort = port;
      toPort = port;
    };
    ssh = mkRule { port = 22; };
    prometheus-node-exporter = mkRule { port = 9002; };
    tailscale = mkRule { port = 41641; };
    http = mkRule { port = 80; };
    https = mkRule { port = 443; };
    loki = mkRule { port = 3100; };
    prometheus = mkRule { port = 9001; };
    dns-udp = mkRule {
      protocol = "udp";
      port = 53;
    };
    dns-tcp = mkRule {
      protocol = "udp";
      port = 53;
    };
  in {
    builder-security-group = { resources, ... }: {
      inherit region;
      description = "Security group for builder.orchard.computer";
      rules = [ ssh prometheus-node-exporter tailscale ];
      vpcId = resources.vpc.vpc-orchard;
    };

    monitor-security-group = { resources, ... }: {
      inherit region;
      description = "Security group for monitor.orchard.computer";
      rules =
        [ ssh prometheus-node-exporter tailscale http https prometheus loki ];
      vpcId = resources.vpc.vpc-orchard;
    };

    networking-security-group = { resources, ... }: {
      inherit region;
      description = "Security group for networking.orchard.computer";
      rules =
        [ ssh prometheus-node-exporter tailscale http https dns-udp dns-tcp ];
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

    networking-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "networking.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.networking ];
    };

    blocky-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "blocky.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.networking ];
    };

    bastion-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "bastion.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.bastion.deployment.targetHost ];
    };

    htpc-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "htpc.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.htpc.deployment.targetHost ];
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
