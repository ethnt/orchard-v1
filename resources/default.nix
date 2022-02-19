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
    nebula = mkRule {
      protocol = "udp";
      port = 4242;
    };
  in {
    monitor-security-group = { resources, ... }: {
      inherit region;
      description = "Security group for monitor.orchard.computer";
      rules = [ ssh nebula ];
    };
  };

  route53HostedZones = {
    orchard-computer = {
      name = "orchard.computer.";
      comment = "Hosted zone for orchard.computer";
    };
  };

  route53RecordSets = {
    sonarr-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "sonarr.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.gateway.networking.publicIPv4 ];
    };

    radarr-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "radarr.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.gateway.networking.publicIPv4 ];
    };

    nzbget-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "nzbget.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.gateway.networking.publicIPv4 ];
    };

    plex-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "plex.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.gateway.networking.publicIPv4 ];
    };
  };
}
