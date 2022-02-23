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
    loki = mkRule { port = 3100; };
    http = mkRule { port = 80; };
    https = mkRule { port = 443; };
    prometheus-node-exporter = mkRule { port = 9002; };
    prometheus-nginx-exporter = mkRule { port = 9113; };
  in {
    monitor-security-group = { resources, ... }: {
      inherit region;
      description = "Security group for monitor.orchard.computer";
      rules = [
        ssh
        nebula
        loki
        http
        https
        prometheus-node-exporter
        prometheus-nginx-exporter
      ];
    };
  };

  elasticIPs = { monitor-elastic-ip = { inherit region; }; };

  route53HostedZones = {
    orchard-computer = {
      name = "orchard.computer.";
      comment = "Hosted zone for orchard.computer";
    };
  };

  route53RecordSets = {
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

    gateway-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "gateway.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.gateway.networking.publicIPv4 ];
    };

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

    prowlarr-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "prowlarr.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.gateway.networking.publicIPv4 ];
    };

    overseerr-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "overseerr.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.gateway.networking.publicIPv4 ];
    };

    tautulli-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "tautulli.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.gateway.networking.publicIPv4 ];
    };

    sabnzbd-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "sabnzbd.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.gateway.networking.publicIPv4 ];
    };

    metrics-satan-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "metrics.satan.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.gateway.networking.publicIPv4 ];
    };

    pve-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "pve.orchard.computer.";
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
