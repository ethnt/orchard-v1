let
  awsConfig = import ../config/aws.nix;
  inherit (awsConfig) region;
in {
  ec2KeyPairs = { deployment-key = { inherit region; }; };

  route53HostedZones = {
    orchard-computer = {
      name = "orchard.computer.";
      comment = "Hosted zone for orchard.computer";
    };
  };

  route53RecordSets = {
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

    arbor-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "arbor.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.bastion.networking.publicIPv4 ];
    };

    plex-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "plex.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.bastion.networking.publicIPv4 ];
    };

    sonarr-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "sonarr.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.bastion.networking.publicIPv4 ];
    };

    radarr-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "radarr.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.bastion.networking.publicIPv4 ];
    };

    nzbget-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "nzbget.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.bastion.networking.publicIPv4 ];
    };

    tautulli-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "tautulli.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.bastion.networking.publicIPv4 ];
    };

    monitor-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "monitor.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.bastion.networking.publicIPv4 ];
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
